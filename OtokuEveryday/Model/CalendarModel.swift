//
//  CalendarModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2023/02/02.
//
import Foundation
import RxSwift
import Firebase
import RxCocoa
import RealmSwift
import AlamofireImage
import PKHUD

protocol CalendarModelInput {
    func authState()
}
protocol CalendarModelOutput {
    var _authStatusObserbable: Observable<AuthStatus> { get }
}
protocol CalendarModelType {
    var input: CalendarModelInput { get }
    var output: CalendarModelOutput { get }
}
// MARK: -
final class CalendarModel {
    private let calendarModel = BehaviorRelay<[OtokuDataModel]>(value: [])
    private let _authStatus = PublishRelay<AuthStatus>()
    private var isUIUpdated = false
    private let imageCache = AutoPurgingImageCache()
    var retryCount = 0
    let maxRetryCount = 3
}
//MARK: - CalendarModel Extension
extension CalendarModel:CalendarModelInput{
    //----------------------------------------------------------------------------------auth判別
    func authState() {
        _authStatus.accept(.retrying) // show HUD
        var handle: AuthStateDidChangeListenerHandle?
        handle = Auth.auth().addStateDidChangeListener({  [weak self] (auth, user) in
            guard let self = self else { return }
            if let currentUser = user, currentUser.isAnonymous {
                self._authStatus.accept(.anonymous)
                if let handle = handle {
                    Auth.auth().removeStateDidChangeListener(handle)
                }
            } else {
                self.retrySignInAnonymously()
            }
        })
    }
    
    func retrySignInAnonymously() {
        if retryCount < maxRetryCount {
            retryCount += 1
            let delay = Double(pow(2.0, Double(retryCount)))
            let workItem = DispatchWorkItem { [weak self] in
                Auth.auth().signInAnonymously { (authResult, error) in
                    guard let self = self else { return }
                    if let user = authResult?.user, error == nil {
                        print("匿名サインインに成功しました", user.uid)
                        self._authStatus.accept(.anonymous)
                    } else {
                        print("匿名サインインに失敗しました:" ,error!.localizedDescription)
                        if self.retryCount == self.maxRetryCount {
                            self._authStatus.accept(.error("リトライ回数を超えました。匿名サインインに失敗しました: \(error!.localizedDescription)"))
                        } else {
                            self._authStatus.accept(.retrying) // show HUD
                            self.retrySignInAnonymously()
                        }
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        }
    }
    
}
extension CalendarModel:CalendarModelOutput{
    var _authStatusObserbable: RxSwift.Observable<AuthStatus> {
        return _authStatus.asObservable()
    }
    var calendarModelObservable: Observable<[OtokuDataModel]> {
        return calendarModel.asObservable()
    }
}
extension CalendarModel: CalendarModelType {
    var input: CalendarModelInput { return self }
    var output: CalendarModelOutput { return self }
}

//-----------------------------------------------------------------------------------------
enum AuthStatus: Equatable {//テストの為Equatable
    case anonymous
    case error(String)
    case retrying
    
    static func == (lhs: AuthStatus, rhs: AuthStatus) -> Bool {
        switch (lhs, rhs) {
        case (.anonymous, .anonymous):
            return true
        case (.error(let lhsMessage), .error(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}
