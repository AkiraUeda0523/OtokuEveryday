//
//  MockFetchCommonDataModel.swift
//  RedMoon2021Tests
//
//  Created by 上田晃 on 2023/10/31.
//

@testable import RedMoon2021
import UIKit
import RxSwift

class MockFetchCommonDataModel: FetchCommonDataModelType, FetchCommonDataModelInput, FetchCommonDataModelOutput {
    var shouldUpdateDataObservable: RxSwift.Observable<Bool> {
        shouldUpdateData.asObservable()
    }
    var mockOtokuData: [OtokuDataModel] = []
    var shouldUpdateData = PublishSubject<Bool>()
    var input: FetchCommonDataModelInput { return self }
    var output: FetchCommonDataModelOutput { return self }
    func bindFetchData() {
       
        mockOtokuData = [
           
        ]
    }
    func updateUIFromRealmData() {
       
        mockOtokuData = [
            
        ]
    }
    var fetchCommonDataModelObservable: Observable<[OtokuDataModel]> {
        return Observable.just(mockOtokuData)
    }
}
