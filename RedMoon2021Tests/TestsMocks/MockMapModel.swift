//
//  MockMapModel.swift
//  RedMoon2021Tests
//
//  Created by 上田晃 on 2023/10/31.
//

import RxSwift
@testable import RedMoon2021

class MockMapModel: MapModelType, MapModelInput, MapModelOutput {
    var output: MapModelOutput { return self }
    var input: MapModelInput { return self }
    // モック用のダミーデータ
    var mockAddressData: [OtokuAddressModel] = []
    var mockAllOtokuData: [OtokuDataModel] = []
    var mockOtokuSpecialtyData: [SlideShowModel] = []
    // ダミーデータのプロパティ
    var otokuSpecialtySubject = PublishSubject<[SlideShowModel]>()
    var shouldUpdateDataJudge = PublishSubject<Bool>()
    var fetchOtokuSpecialtyDataCalled = false
    var otokuSpecialtyObservable: Observable<[SlideShowModel]> {
        return otokuSpecialtySubject.asObservable()
    }
    // MapModelOutputのプロパティ
    var AddressDataObservable: Observable<[OtokuAddressModel]> {
        return Observable.just(mockAddressData)
    }
    var AllOtokuDataObservable: Observable<[OtokuDataModel]> {
        return Observable.just(mockAllOtokuData)
    }
    var shouldUpdateDataJudgeObserver: AnyObserver<Bool> {
        return shouldUpdateDataJudge.asObserver()
    }
    // MapModelInputのメソッド
    func fetchOtokuSpecialtyData() {
        fetchOtokuSpecialtyDataCalled = true
        // 他のダミーの処理...
    }
    // MapModelInputのメソッド
    func fetchAddressDataFromRealTimeDB() {
        // 何もしないか、必要に応じてBehaviorRelayやSubjectにダミーデータを送信する
    }
    func fetchAllOtokuDataFromRealTimeDB() {
        // 同上
    }
}
