//
//  MockCalendarModel.swift
//  RedMoon2021Tests
//
//  Created by 上田晃 on 2023/11/22.
//
import RxSwift
import RxCocoa
@testable import RedMoon2021


class MockCalendarModel: CalendarModelType, CalendarModelInput, CalendarModelOutput {
    var input: CalendarModelInput { return self }
    var output: CalendarModelOutput { return self }

    private var mockAuthStatus: AuthStatus = .anonymous
    private var mockCalendarData: [OtokuDataModel] = []
    private let _authStatus = PublishRelay<AuthStatus>()
    
    func authState() {
      
        _authStatus.accept(mockAuthStatus)
    }
    
    var _authStatusObserbable: Observable<AuthStatus> {
        return _authStatus.asObservable()
    }
    
    var calendarModelObservable: Observable<[OtokuDataModel]> {
        return Observable.just(mockCalendarData)
    }

    func setMockData(data: [OtokuDataModel]) {
        mockCalendarData = data
    }

    func setMockAuthStatus(status: AuthStatus) {
        mockAuthStatus = status
    }
}

