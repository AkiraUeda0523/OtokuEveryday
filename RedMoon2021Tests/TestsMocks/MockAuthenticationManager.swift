//
//  MockCalendarModel.swift
//  RedMoon2021Tests
//
//  Created by 上田晃 on 2023/11/22.
//
import RxSwift
import RxCocoa
@testable import RedMoon2021

class MockAuthenticationManager: AuthenticationManagerType, AuthenticationManagerInput, AuthenticationManagerOutput {
    var input: AuthenticationManagerInput { return self }
    var output: AuthenticationManagerOutput { return self }

    private var mockAuthStatus: AuthStatus = .anonymous
    private var mockCalendarData: [OtokuDataModel] = []
    private let authStatusRelay = PublishRelay<AuthStatus>()
    func initializeAuthStateListener() {
        // ここでモック認証状態を設定
        // 例: 常に匿名ユーザーとして扱う
        authStatusRelay.accept(mockAuthStatus)
    }
    var authStatusObservable: Observable<AuthStatus> {
        return authStatusRelay.asObservable()
    }
//    var calendarModelObservable: Observable<[OtokuDataModel]> {
//        // モックデータをObservableとして返す
//        return Observable.just(mockCalendarData)
//    }
    // テストやデモのための追加メソッドやプロパティをここに追加可能
    // 例: モックデータの設定や更新
    func setMockData(data: [OtokuDataModel]) {
        mockCalendarData = data
    }

    func setMockAuthStatus(status: AuthStatus) {
        mockAuthStatus = status
    }
}
