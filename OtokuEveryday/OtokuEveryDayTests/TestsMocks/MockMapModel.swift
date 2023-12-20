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
    
    var mockAddressData: [OtokuAddressModel] = []
    var mockAllOtokuData: [OtokuDataModel] = []
    var mockOtokuSpecialtyData: [SlideShowModel] = []
    
    var otokuSpecialtySubject = PublishSubject<[SlideShowModel]>()
    var shouldUpdateDataJudge = PublishSubject<Bool>()
    var fetchOtokuSpecialtyDataCalled = false
    
    var otokuSpecialtyObservable: Observable<[SlideShowModel]> {
        return otokuSpecialtySubject.asObservable()
    }
    
    var AddressDataObservable: Observable<[OtokuAddressModel]> {
        return Observable.just(mockAddressData)
    }
    var AllOtokuDataObservable: Observable<[OtokuDataModel]> {
        return Observable.just(mockAllOtokuData)
    }
    var shouldUpdateDataJudgeObserver: AnyObserver<Bool>{
        return shouldUpdateDataJudge.asObserver()
    }
    
    func fetchOtokuSpecialtyData() {
        fetchOtokuSpecialtyDataCalled = true
       
    }
   
    func fetchAddressDataFromRealTimeDB() {
    }
    func fetchAllOtokuDataFromRealTimeDB() {
    }
}
