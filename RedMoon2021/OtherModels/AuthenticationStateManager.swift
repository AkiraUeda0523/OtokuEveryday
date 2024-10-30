//
//  AuthenticationStateManager.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2023/02/02.
//

import Foundation
import RxSwift
import Firebase
import RxCocoa
// MARK: - Protocols
protocol AuthenticationManagerInput {
    func initializeAuthStateListener()
}
protocol AuthenticationManagerOutput {
    var authStatusObservable: Observable<AuthStatus> { get }
}
protocol AuthenticationManagerType {
    var input: AuthenticationManagerInput { get }
    var output: AuthenticationManagerOutput { get }
}
// MARK: - Main Class
final class AuthenticationStateManager {
    private let authStatusRelay = PublishRelay<AuthStatus>()
    var retryCount = 0
    let maxRetryCount = 3
}
// MARK: - Input Implementation
extension AuthenticationStateManager: AuthenticationManagerInput {
    // Firebase認証状態のリスナーを初期化し、ユーザーの認証状態を監視するメソッド
    func initializeAuthStateListener() {
        // 認証状態の初期状態として「再試行中」を設定
        authStatusRelay.accept(.retrying)
        // Firebase認証の状態変更リスナーを設定
        var handle: AuthStateDidChangeListenerHandle?
        handle = Auth.auth().addStateDidChangeListener({ [weak self] ( _, user) in
            // クロージャ内で弱参照のselfをアンラップ
            guard let self = self else { return }
            // ユーザーが匿名ユーザーであるかどうかをチェック
            if let currentUser = user, currentUser.isAnonymous {
                // 匿名ユーザーであれば、認証状態を「匿名」に設定
                self.authStatusRelay.accept(.anonymous)
                // 認証リスナーを解除
                if let handle = handle {
                    Auth.auth().removeStateDidChangeListener(handle)
                }
            } else {
                // ユーザーが匿名ユーザーでなければ、再試行を開始
                Task {
                    await self.retrySignInAnonymously()
                }
            }
        })
    }
    // 匿名ユーザーとしてFirebaseに再試行してサインインするメソッド
    func retrySignInAnonymously() async {
        // 最大再試行回数までループ
        for _ in 1...maxRetryCount {
            do {
                // Firebaseで匿名認証を試行
                let authResult = try await Auth.auth().signInAnonymously()
                print("匿名サインインに成功しました", authResult.user.uid)
                self.authStatusRelay.accept(.anonymous)
                return // 成功したら関数を終了
            } catch {
                // 認証失敗時の処理
                self.authStatusRelay.accept(.error("リトライ回数を超えました。匿名サインインに失敗しました: \(error.localizedDescription)"))
                // 指定された時間（指数関数的に増加）スリープ
                try? await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(retryCount)) * 1_000_000_000))
            }
        }
        // 最大試行回数後に再試行状態を設定
        self.authStatusRelay.accept(.retrying)
    }
}
// MARK: - Output Implementation
extension AuthenticationStateManager: AuthenticationManagerOutput {
    var authStatusObservable: RxSwift.Observable<AuthStatus> {
        return authStatusRelay.asObservable()
    }
}
// MARK: - Additional Extensions
extension AuthenticationStateManager: AuthenticationManagerType {
    var input: AuthenticationManagerInput { return self }
    var output: AuthenticationManagerOutput { return self }
}
// MARK: -
enum AuthStatus: Equatable { // Equatableプロトコルを採用
    case anonymous // 匿名ユーザーの状態
    case error(String) // エラー状態、エラーメッセージを保持
    case retrying // 認証再試行中の状態
    // Equatableプロトコルの実装（テスト使用）
    static func == (lhs: AuthStatus, rhs: AuthStatus) -> Bool {
        switch (lhs, rhs) {
        case (.anonymous, .anonymous):
            // 両方とも匿名状態の場合は等しいと判断
            return true
        case (.error(let lhsMessage), .error(let rhsMessage)):
            // 両方ともエラー状態で、エラーメッセージが等しい場合は等しいと判断
            return lhsMessage == rhsMessage
        default:
            // その他の組み合わせでは、等しくないと判断
            return false
        }
    }
}
