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
    // FetchCommonDataModelInput の実装
    func isRealmDataEmpty() {
        // ここで必要なモックの動作を設定します。
        // 例: ダミーのデータを使用して、通常の動作をシミュレートする。
        mockOtokuData = [
            // ここにダミーのOtokuDataModelを追加します。
            // OtokuDataModel(...)
        ]
    }
    func updateUIFromRealmData() {
        // ここでUIを更新するためのモックの動作を設定します。
        // 例: ダミーのデータを使用して、通常の動作をシミュレートする。
        mockOtokuData = [
            // ここにダミーのOtokuDataModelを追加します。
            // OtokuDataModel(...)
        ]
    }
    // FetchCommonDataModelOutput の実装
    var fetchCommonDataModelObservable: Observable<[OtokuDataModel]> {
        // ここではダミーの mockOtokuData を返す
        return Observable.just(mockOtokuData)
    }
}
