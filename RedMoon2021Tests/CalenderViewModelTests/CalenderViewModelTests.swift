//
//  CalenderViewModelTests.swift
//  RedMoon2021Tests
//
//  Created by 上田晃 on 2023/11/22.
//
import Swinject
import XCTest
import RxSwift
import RxCocoa
import RxTest
import RxBlocking

@testable import RedMoon2021

class CalenderViewModelTests: XCTestCase {
    var calendarViewModel: CalendarViewModel!
    var disposeBag: DisposeBag!
    var scheduler: TestScheduler!
    var container: Container!
    var mockCalendarModel: AuthenticationManagerType!
    var mockAdMobModel: SetAdMobModelType!
    var mockTodayDateModel: FetchTodayDateModelType!
    var mockAutoScrollModel: AutoScrollModelType!
    var mockCommonDataModel: FetchCommonDataModelType!
    override func setUp() {
        super.setUp()
        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()
        container = Container()
        // モックオブジェクトの登録
        container.register(AuthenticationManagerType.self) { _ in MockAuthenticationManager() }
        container.register(SetAdMobModelType.self) { _ in MockSetAdMobModel() }
        container.register(FetchTodayDateModelType.self) { _ in MockFetchTodayDateModel() }
        container.register(AutoScrollModelType.self) { _ in MockAutoScrollModel() }
        container.register(FetchCommonDataModelType.self) { _ in MockFetchCommonDataModel() }
        container.register(CalendarViewModel.self) { resolver in
            CalendarViewModel(
                authenticationManager: resolver.resolve(AuthenticationManagerType.self)!,
                adMobModel: resolver.resolve(SetAdMobModelType.self)!,
                todayDateModel: resolver.resolve(FetchTodayDateModelType.self)!,
                autoScrollModel: resolver.resolve(AutoScrollModelType.self)!,
                commonDataModel: resolver.resolve(FetchCommonDataModelType.self)!
            )!
        }
        if let viewModel = container.resolve(CalendarViewModel.self) {
            calendarViewModel = viewModel
        } else {
            XCTFail("Failed to resolve CalendarViewModel")
        }
        // モックオブジェクトの解決
        mockCalendarModel = container.resolve(AuthenticationManagerType.self) as? MockAuthenticationManager
        mockAdMobModel = container.resolve(SetAdMobModelType.self) as? MockSetAdMobModel
        mockTodayDateModel = container.resolve(FetchTodayDateModelType.self) as? MockFetchTodayDateModel
        mockAutoScrollModel = container.resolve(AutoScrollModelType.self) as? MockAutoScrollModel
        mockCommonDataModel = container.resolve(FetchCommonDataModelType.self) as? MockFetchCommonDataModel
    }
    override func tearDown() {
        calendarViewModel = nil
        disposeBag = nil
        container = nil
        super.tearDown()
    }
    // ViewWidthSizeSubjectのテスト
    func testViewWidthSizeSubscription() {
        let expectedWidth: CGFloat = 320
        let expectedHeight: CGFloat = 50
        let viewController = UIViewController()
        guard let mockAdMobModel = mockAdMobModel as? MockSetAdMobModel else {
            XCTFail("Failed to resolve MockSetAdMobModel")
            return
        }
        calendarViewModel
            .viewWidthSizeSubject
            .subscribe(onNext: { [weak self] size in
                guard let self = self else { return }
                self.mockAdMobModel?.setAdMob(bannerWidthSize: size.bannerWidth, bannerHight: size.bannerHeight, viewController: viewController)
            })
            .disposed(by: disposeBag)
        calendarViewModel
            .input
            .viewWidthSizeObserver
            .onNext(SetAdMobModelData(bannerWidth: expectedWidth, bannerHight: expectedHeight, VC: viewController))
        XCTAssertEqual(mockAdMobModel.setAdMobCalledWith?.bannerWidthSize, expectedWidth)
        XCTAssertEqual(mockAdMobModel.setAdMobCalledWith?.bannerHight, expectedHeight)
        XCTAssertEqual(mockAdMobModel.setAdMobCalledWith?.VC, viewController)
    }
    func testMockFetchCommonDataModelSubscription() {
        let dummyOtokuDataModel: OtokuDataModel = OtokuDataModel(
            address_ids: ["dummyAddressId"],
            article_title: "Dummy Title",
            blog_web_url: "https://dummyurl.com",
            collectionView_image_url: "https://dummyimageurl.com",
            enabled_dates: ["2023-01-01"]
        )
        guard let mockCommonDataModel = mockCommonDataModel as? MockFetchCommonDataModel else {
            XCTFail("Failed to resolve MockFetchCommonDataModel")
            return
        }
        mockCommonDataModel.mockOtokuData = [dummyOtokuDataModel]
        mockCommonDataModel
            .fetchCommonDataModelObservable
            .subscribe(onNext: { [unowned self] data in
                calendarViewModel.articlesSubject.onNext(data)
            })
            .disposed(by: disposeBag)
        calendarViewModel
            .articlesSubject
            .subscribe(onNext: { data in
                XCTAssertEqual(data, [dummyOtokuDataModel])
            })
            .disposed(by: disposeBag)
        //        mockCommonDataModel.bindFetchData() // モックのデータをバインドするためのメソッドを呼び出す
    }
    func testAuthState() {
        let expect = expectation(description: "AuthStatusが正しく放出される")
        let expectedAuthStatus: AuthStatus = .anonymous // またはテストするAuthStatusに応じて変更
        guard let mockCalendarModel = mockCalendarModel as? MockAuthenticationManager else {
            XCTFail("Failed to resolve MockCalendarModel")
            return
        }
        //        let viewModel = CalendarViewModel(calendarModel: mockCalendarModel, adMobModel: mockAdMobModel, todayDateModel: mockTodayDateModel, autoScrollModel: mockAutoScrollModel, commonDataModel: mockCommonDataModel)
        calendarViewModel
            .authStateSubject
            .observe(on: MainScheduler.instance) // メインスレッドで実行を保証
            .subscribe(onNext: { authStatus in
                XCTAssertEqual(authStatus, expectedAuthStatus)
                expect.fulfill()
            })
            .disposed(by: disposeBag)
        mockCalendarModel.initializeAuthStateListener()
        // モックのAuthStatusを設定
        mockCalendarModel.setMockAuthStatus(status: expectedAuthStatus)
        wait(for: [expect], timeout: 5.0)
    }
    func testAutoScrollLabelLayoutArrange() {
        //                let viewModel = CalendarViewModel(calendarModel: mockCalendarModel, adMobModel: mockAdMobModel, todayDateModel: mockTodayDateModel, autoScrollModel: mockAutoScrollModel, commonDataModel: mockCommonDataModel)
        // テスト用のビューの境界
        let bounds = CGRect(x: 0, y: 0, width: 414, height: 30)
        // 期待される AutoScrollModel オブジェクトの生成
        //        let expectedLayout = AutoScrollModel(frame: bounds)
        //        let expectedLayout = mockAutoScrollModel.input.autoScrollLabelLayoutArrange(scrollBaseViewsBounds: bounds)
        //
        //        expectedLayout.backgroundColor = .white
        //        expectedLayout.textColor = .black
        //        expectedLayout.font = .systemFont(ofSize: 26)
        //        expectedLayout.text = "2021年 1月 1日（金）"
        // サブスクライブの設定
        calendarViewModel.autoScrollModelsLayoutSubject
            .subscribe(onNext: { layout in
                // ここで、実際に返されたレイアウト情報と期待値を比較します。
                //                XCTAssertEqual(layout.frame, expectedLayout.frame)
                XCTAssertEqual(layout.frame, bounds)
                //                XCTAssertEqual(layout.backgroundColor, expectedLayout.backgroundColor)
                //                XCTAssertEqual(layout.textColor, expectedLayout.textColor)
                //                XCTAssertEqual(layout.font, expectedLayout.font)
                //                XCTAssertEqual(layout.text, expectedLayout.text)
            })
            .disposed(by: disposeBag)
        // テストの実行
        calendarViewModel.scrollBaseViewBoundsSubject.onNext(bounds)
    }
    func testCollectionViewSelectedIndexPathSubscription() {
        // テストデータの準備
        let testIndexPath = IndexPath(row: 0, section: 0)
        let testData = [
            OtokuDataModel(
                address_ids: ["id1"],
                article_title: "Title 1",
                blog_web_url: "https://example1.com",
                collectionView_image_url: "https://image1.com",
                enabled_dates: ["2023-01-01"]
            ),
            OtokuDataModel(
                address_ids: ["id2"],
                article_title: "Title 2",
                blog_web_url: "https://example2.com",
                collectionView_image_url: "https://image2.com",
                enabled_dates: ["2023-01-02"]
            )
        ]
        // showableInfosRelayにテストデータを設定
        calendarViewModel.showableInfosRelay.accept(testData)
        // テストの実行
        calendarViewModel.collectionViewSelectedIndexPathSubject.onNext(testIndexPath)
        // 期待される結果の検証
        let expectedUrl = testData[testIndexPath.row].blog_web_url
        let result = try! calendarViewModel.collectionViewSelectedUrlRelay.toBlocking(timeout: 5).first()
        XCTAssertEqual(result, expectedUrl)
    }
    func testCombineLatestStream() {
        // テストデータの準備
        let mockDate = Date(timeIntervalSince1970: 0) // 1970-01-01
        let mockArticles = [
            OtokuDataModel(
                address_ids: ["address1"],
                article_title: "Article Title 1",
                blog_web_url: "https://example.com/article1",
                collectionView_image_url: "https://example.com/image1.jpg",
                enabled_dates: ["1970-01-01"]
            ),
            OtokuDataModel(
                address_ids: ["address2"],
                article_title: "Article Title 2",
                blog_web_url: "https://example.com/article2",
                collectionView_image_url: "https://example.com/image2.jpg",
                enabled_dates: ["1970-01-02"]
            )
        ]
        let mockLayout = mockAutoScrollModel // ここで適切なAutoScrollModelを初期化
                // TestableObserverの作成
        let observer = scheduler.createObserver(AutoScrollModelType.self)
        // スケジューラを使用してObservableにテストデータを供給
        scheduler.createColdObservable([.next(10, mockDate)])
            .bind(to: calendarViewModel.calendarSelectedDateSubject)
            .disposed(by: disposeBag)
        scheduler.createColdObservable([.next(10, mockArticles)])
            .bind(to: calendarViewModel.showableInfosRelay)
            .disposed(by: disposeBag)
        // mockLayout が nil でないことを確認してからバインドする
        if let mockLayout = mockLayout {
            let mockObservable = scheduler.createColdObservable([.next(10, mockLayout)])
            mockObservable
                .bind(to: calendarViewModel.autoScrollModelsLayoutSubject)
                .disposed(by: disposeBag)
        } else {
            // mockLayout が nil の場合の処理
            // 適切なエラーハンドリングを行う
        }
        // 結果のObservableをobserverにバインド
        calendarViewModel.autoScrollViewSubject
            .bind(to: observer)
            .disposed(by: disposeBag)
        // スケジューラの実行
        scheduler.start()
        // 期待される結果との比較
        let expectedText = "【1月1日のお得情報】Article Title 1　　　Article Title 2"
        // observer.events から AutoScrollModelType インスタンスの配列を取得し、
        // それらの text プロパティを取り出して配列にする
        let actualTexts = observer.events.compactMap { event in
            event.value.element?.text
        }
        // 期待されるイベントの配列を作成する
        let expectedEvents = [
            Recorded.next(10, expectedText)
        ].compactMap { event in
            event.value.element
        }
        // 実際のイベントの配列と期待されるイベントの配列を比較する
        XCTAssertEqual(actualTexts, expectedEvents)
    }
}
