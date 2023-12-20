//
//  MockFetchTodayDateModel.swift
//  RedMoon2021Tests
//
//  Created by 上田晃 on 2023/10/31.
//

@testable import RedMoon2021

class MockFetchTodayDateModel: FetchTodayDateModelType, FetchTodayDateModelInput {
    var input: FetchTodayDateModelInput { return self }

    private var mockDate: String = "01"

    func fetchTodayDate() -> String {
        return mockDate
    }
    func setMockDate(date: String) {
        mockDate = date
    }
}
