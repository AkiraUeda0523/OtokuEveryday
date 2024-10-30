//import RxSwift
//import GoogleMobileAds
//@testable import RedMoon2021
//
//
//// Generated using Sourcery 2.1.2 — https://github.com/krzysztofzablocki/Sourcery
//// DO NOT EDIT
//
//// sourcery:inline:CalendarViewModelInput.Mock
//class CalendarViewModelInputMock: CalendarViewModelInput {
//    var calendarSelectedDateObserverReturnValue: AnyObserver<Date>!
//    var viewWidthSizeObserverReturnValue: AnyObserver<SetAdMobModelData>!
//    var collectionViewSelectedIndexPathObserverReturnValue: AnyObserver<IndexPath>!
//    var scrollBaseViewsBoundsObservableReturnValue: AnyObserver<CGRect>!
//
//    // sourcery:begin: CalendarViewModelInput
//    var calendarSelectedDateObserver: AnyObserver<Date> {
//        return calendarSelectedDateObserverReturnValue
//    }
//    var viewWidthSizeObserver: AnyObserver<SetAdMobModelData> {
//        return viewWidthSizeObserverReturnValue
//    }
//    var collectionViewSelectedIndexPathObserver: AnyObserver<IndexPath> {
//        return collectionViewSelectedIndexPathObserverReturnValue
//    }
//    var scrollBaseViewsBoundsObservable: AnyObserver<CGRect> {
//        return scrollBaseViewsBoundsObservableReturnValue
//    }
//    // sourcery:end
//}
//// sourcery:endinline
//
//// sourcery:inline:CalendarViewModelOutput.Mock
//class CalendarViewModelOutputMock: CalendarViewModelOutput {
//    var showableInfosObservableReturnValue: Observable<[OtokuDataModel]>!
//    var authStateObservableReturnValue: Observable<AuthStatus>!
//    var isLoadingObservableReturnValue: Observable<Bool>!
//    var setAdMobBannerObservableReturnValue: Observable<GADBannerView>!
//    var collectionViewSelectedUrlObservableReturnValue: Observable<String>!
//    var autoScrollModelObservableReturnValue: Observable<AutoScrollModel>!
//
//    // sourcery:begin: CalendarViewModelOutput
//    var showableInfosObservable: Observable<[OtokuDataModel]> {
//        return showableInfosObservableReturnValue
//    }
//    var authStateObservable: Observable<AuthStatus> {
//        return authStateObservableReturnValue
//    }
//    var isLoadingObservable: Observable<Bool> {
//        return isLoadingObservableReturnValue
//    }
//    var setAdMobBannerObservable: Observable<GADBannerView> {
//        return setAdMobBannerObservableReturnValue
//    }
//    var collectionViewSelectedUrlObservable: Observable<String> {
//        return collectionViewSelectedUrlObservableReturnValue
//    }
//    var autoScrollModelObservable: Observable<AutoScrollModel> {
//        return autoScrollModelObservableReturnValue
//    }
//    // sourcery:end
//}
//// sourcery:endinline
//
//// sourcery:inline:CalendarViewModelType.Mock
//class CalendarViewModelTypeMock: CalendarViewModelType {
//    var inputReturnValue: CalendarViewModelInputMock!
//    var outputReturnValue: CalendarViewModelOutputMock!
//
//    // sourcery:begin: CalendarViewModelType
//    var input: CalendarViewModelInput {
//        return inputReturnValue
//    }
//    var output: CalendarViewModelOutput {
//        return outputReturnValue
//    }
//    // sourcery:end
//}
//// sourcery:endinline
//
//
//import XCTest
//import RxSwift
//import RxTest
//
//class CalendarViewModelTests: XCTestCase {
//    var viewModel: CalendarViewModel!
//    var mockInput: CalendarViewModelInputMock!
//    var mockOutput: CalendarViewModelOutputMock!
//    var disposeBag: DisposeBag!
//
//    override func setUp() {
//        super.setUp()
//        disposeBag = DisposeBag()
//        mockInput = CalendarViewModelInputMock()
//        mockOutput = CalendarViewModelOutputMock()
//        viewModel = CalendarViewModel(calendarViewModel: mockInput, adMobModel: mockOutput, fetchTodayDateModel: mockOutput, autoScrollModel: mockOutput, fetchCommonDataModel: mockOutput)
//    }
//
//    override func tearDown() {
//        viewModel = nil
//        mockInput = nil
//        mockOutput = nil
//        disposeBag = nil
//        super.tearDown()
//    }
//
//    func testAuthStateObservable() {
//        // スケジューラーを設定
//        let scheduler = TestScheduler(initialClock: 0)
//
//        // 期待されるイベントを設定
//        let expectedEvents = [
//            .next(10, AuthStatus.authorized),
//            .completed(10)
//        ]
//
//        // オブザーバブルをモックに設定
//        let authStateObservable = scheduler.createHotObservable(expectedEvents)
//        mockOutput.authStateObservableReturnValue = authStateObservable.asObservable()
//
//        // テスト対象のObservableを購読
//        let observer = scheduler.createObserver(AuthStatus.self)
//        viewModel.output.authStateObservable
//            .bind(to: observer)
//            .disposed(by: disposeBag)
//
//        // スケジューラーを開始
//        scheduler.start()
//
//        // 期待される結果をアサート
//        XCTAssertEqual(observer.events, expectedEvents)
//    }
//
//    // 他のテストケースも同様に書きます。
//}
//
//
