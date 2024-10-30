//
//  MockFetchTodayDateModel.swift
//  RedMoon2021Tests
//
//  Created by 上田晃 on 2023/10/31.
//

@testable import RedMoon2021

class MockFetchTodayDateModel: FetchTodayDateModelType, FetchTodayDateModelInput {
    var input: FetchTodayDateModelInput { return self }
    private var mockDate: String = "01" // デフォルトのモック日付
    func fetchTodayDate() -> String {
        // 実際の日付取得の代わりにモックの日付を返す
        return mockDate
    }
    // テストのためにモックの日付を設定するメソッド
    func setMockDate(date: String) {
        mockDate = date
    }
}
