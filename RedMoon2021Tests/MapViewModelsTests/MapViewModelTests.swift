//
//  MapViewModelTests.swift
//  RedMoon2021Tests
//
//  Created by 上田晃 on 2023/08/05.
//

import XCTest
import RxSwift
import RxCocoa
import RxTest
import RxBlocking
import MapKit

@testable import RedMoon2021

class MapViewModelTests: XCTestCase {
    var mapViewModel: MapViewModel!
    var slideShowSelectedIndexPath: IndexPath!
    var disposeBag: DisposeBag!
    var scheduler: TestScheduler!
    let mockMapModel = MockMapModel()
    let mockAdMobModel = MockSetAdMobModel()
    let mockTodayDateModel = MockFetchTodayDateModel()
    let mockCommonDataModel = MockFetchCommonDataModel()
    let mockAuthenticationManager = MockAuthenticationManager()
    let mockFirestoreWrapper = MockFirestoreWrapper()
    override func setUp() {
        super.setUp()
        slideShowSelectedIndexPath = IndexPath(row: 0, section: 0)
        scheduler = TestScheduler(initialClock: 0)
        mapViewModel = MapViewModel(model: mockMapModel, adMobModel: mockAdMobModel, fetchTodayDateModel: mockTodayDateModel, commonDataModel: mockCommonDataModel, authenticationManager: mockAuthenticationManager, firestoreService: mockFirestoreWrapper)
        disposeBag = DisposeBag()
    }
    override func tearDown() {
        mapViewModel = nil
        disposeBag = nil
        super.tearDown()
    }
    func testOtokuSpecialtyObservable_ShouldReturnMockData() {
        // Arrange
        let expectedData = mockMapModel.mockOtokuSpecialtyData // これはモックデータに基づく期待されるデータです。
        // Act
        let data = try! mapViewModel.otokuSpecialtyObservable.toBlocking().first()!
        // Assert
        XCTAssertEqual(data, expectedData)
    }
    func testMoveModelBoxFirstIfNeededForTodaysAnnotationModel() {
        // Arrange
        let mockData = [
            OtokuMapModel(address: OtokuAddressModel(address_id: "1", content: "", latitude: nil, longitude: nil), article_title: "", blog_web_url: "", id: ""),
            OtokuMapModel(address: OtokuAddressModel(address_id: "2", content: "", latitude: 0.0, longitude: 0.0), article_title: "", blog_web_url: "", id: "")
        ]
        mapViewModel.setupTestDataForTest(addAnnotationRetryCount: 0, selectSegmentIndexType: 0, todaysAnnotationModel: mockData)
        // Act
        mapViewModel.moveModelBoxFirstIfNeededForTest()  // テスト用のメソッドを呼び出します
        // Assert
        XCTAssertFalse(mapViewModel.getTodaysAnnotationModelForTest().contains(where: { $0.address.longitude == nil }))
    }
    func testMoveModelBoxFirstIfNeededForAllDaysAnnotationModel() {
        // Arrange
        let mockData = [
            OtokuMapModel(address: OtokuAddressModel(address_id: "1", content: "", latitude: nil, longitude: nil), article_title: "", blog_web_url: "", id: ""),
            OtokuMapModel(address: OtokuAddressModel(address_id: "2", content: "", latitude: 0.0, longitude: 0.0), article_title: "", blog_web_url: "", id: "")
        ]
        mapViewModel.setupTestDataForAllDaysAnnotationModelTest(addAnnotationRetryCount: 0, selectSegmentIndexType: 1, allDaysAnnotationModel: mockData)
        // Act
        mapViewModel.moveModelBoxFirstIfNeededForTest()  // テスト用のメソッドを呼び出します
        // Assert
        XCTAssertFalse(mapViewModel.getAllDaysAnnotationModelForTest().contains(where: { $0.address.longitude == nil }))
    }
    func testSlideShowCollectionViewSelectedUrlObservable() {
        // Arrange
        let expectedUrl = "https://example.com"
        let mockIndexPath = IndexPath(row: 0, section: 0)
        let models = [SlideShowModel(input: ["webUrl": expectedUrl, "address": "", "title": "", "image": "", "comment": ""])]
        let mockData = models.compactMap { $0 }
        mapViewModel.otokuSpecialtySubject.onNext(mockData)
        var observedUrl: String? = nil
        let disposeBag = DisposeBag() // このDisposeBagをテストのライフサイクル全体で使い続ける
        mapViewModel.output.slideShowCollectionViewSelectedUrlObservavable.subscribe(onNext: {
            observedUrl = $0
        }).disposed(by: disposeBag)
        // Act
        mapViewModel.input.slideShowCollectionViewSelectedIndexPathObserver.onNext(mockIndexPath)
        // Assert
        XCTAssertEqual(observedUrl, expectedUrl)
    }
    func testViewWidthSizeSubscription() {
        let widthSizeData = SetAdMobModelData(bannerWidth: 200, bannerHight: 200, VC: UIViewController())
        mapViewModel.input.viewWidthSizeObserver.onNext(widthSizeData)
        XCTAssertEqual(mockAdMobModel.setAdMobCalledWith?.bannerWidthSize, 200)
    }
    //    func testFetchMapAllDataTriggerSubscription() {
    //        mapViewModel.input.fetchMapAllDataTriggerObserver.onNext(())
    //        XCTAssertTrue(mockMapModel.fetchOtokuSpecialtyDataCalled)
    //    }
    func testOtokuSpecialtyObservableSubscription() {
        // SlideShowModelの初期化
        let dummyInput: [String: Any] = [
            "webUrl": "http://dummy.url",
            "address": "Dummy Address",
            "title": "DummyTitle",
            "image": "dummyImageURL",
            "comment": "Dummy Comment"
        ]
        guard let expectedDataModel = SlideShowModel(input: dummyInput) else {
            XCTFail("Failed to initialize SlideShowModel")
            return
        }
        let expectedData = [expectedDataModel]
        mockMapModel.otokuSpecialtySubject.onNext(expectedData)
        var observedData: [SlideShowModel]? = nil
        let disposeBag = DisposeBag()
        mapViewModel.output.otokuSpecialtyObservable.subscribe(onNext: {
            observedData = $0
        }).disposed(by: disposeBag)
        XCTAssertEqual(observedData, expectedData)
    }
    func testSlideShowCollectionViewSelectedUrlSubscription() {
        // otokuSpecialtySubjectへのダミーデータの供給
        let dummyInput: [String: Any] = [
            "webUrl": "http://example.com",
            "address": "Dummy Address",
            "title": "DummyTitle",
            "image": "dummyImageURL",
            "comment": "Dummy Comment"
        ]
        guard let dummyModel = SlideShowModel(input: dummyInput) else {
            XCTFail("Failed to initialize SlideShowModel")
            return
        }
        mockMapModel.otokuSpecialtySubject.onNext([dummyModel])
        let expectedUrl = "http://example.com"
        var observedUrl: String? = nil
        let disposeBag = DisposeBag() // このDisposeBagをテストのライフサイクル全体で使い続ける
        mapViewModel.output.slideShowCollectionViewSelectedUrlObservavable.subscribe(onNext: {
            observedUrl = $0
        }).disposed(by: disposeBag)
        mapViewModel.input.slideShowCollectionViewSelectedIndexPathObserver.onNext(IndexPath(row: 0, section: 0))
        XCTAssertEqual(observedUrl, expectedUrl)
    }
    func testProcessBoxGeocoding() {
        // 1. Setup MockGeocoder
        let expectedPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917))
        let mockGeocoder = MockGeocoder(result: expectedPlacemark, error: nil)
        // 2. Replace mapViewModel's addressGeocoder with the mock
        mapViewModel.addressGeocoder = mockGeocoder
        // 3. Setup MockFirestore and set it to mapViewModel
        let mockFirestore = MockFirestoreWrapper()
        mapViewModel.firestoreService = mockFirestore
        // 4. Call processBox with mock data
        let testAddress = OtokuAddressModel(address_id: "testID", content: "Test Address", latitude: nil, longitude: nil)
        let testBox = OtokuMapModel(address: testAddress, article_title: "Test", blog_web_url: "https://test.com", id: "testID")
        mapViewModel.processBox(testBox)
        // 5. Verify results: check if expected latitude and longitude values were set correctly
        // 5. Verify results
        if let callDetails = mockFirestore.setDataCalledWith {
            let savedLatitude = callDetails.data["latitude"] as? Double
            let savedLongitude = callDetails.data["longitude"] as? Double
            
            XCTAssertEqual(savedLatitude, 35.6895)
            XCTAssertEqual(savedLongitude, 139.6917)
        } else {
            XCTFail("setData was not called on the mockFirestore.")
        }
    }
    func testModelBoxObservable() {// ⚠️
//        mapViewModel.currentSegmente.accept(.all) // または .today、テストのシナリオに応じて選択
        // 1. Mockデータの準備
        let mockAddress = OtokuAddressModel(
            address_id: "testID",
            content: "Test Address",
            latitude: nil,
            longitude: nil
        )
        let mockArticle = OtokuDataModel(
            address_ids: [mockAddress.address_id],
            article_title: "Test Article",
            blog_web_url: "https://example.com",
            collectionView_image_url: "https://example.com/image.jpg",
            enabled_dates: ["2023-10-28"]
        )
        // 3. Address Geocodingのモック
        let mockPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917))
        let mockGeocoder = MockGeocoder(result: mockPlacemark, error: nil)
        mapViewModel.addressGeocoder = mockGeocoder
        // 4. Firestoreのモック
        let mockFirestore = MockFirestoreWrapper()
        mapViewModel.firestoreService = mockFirestore
        mapViewModel.addressSubject.onNext([mockAddress])
        mapViewModel.articlesSubject.onNext([mockArticle])
        XCTAssert(mockFirestore.collectionCalledWith == "map_ addresses")
        XCTAssert(mockFirestore.documentCalledWith == "testID")
        XCTAssert(mockFirestore.setDataCalledWith?.data["latitude"] as? Double == 35.6895)
        XCTAssert(mockFirestore.setDataCalledWith?.data["longitude"] as? Double == 139.6917)
    }
    func testHandleGeocodingResult() {
        // 1. Mockデータの準備
        let mockAddress = OtokuAddressModel(
            address_id: "testID",
            content: "Test Address",
            latitude: nil,
            longitude: nil
        )
        let mockBox = OtokuMapModel(
            address: mockAddress,
            article_title: "Test Article",
            blog_web_url: "https://example.com",
            id: "testID"
        )
        let mockLocation = CLLocation(latitude: 35.6895, longitude: 139.6917)
        let mockPlacemark = MKPlacemark(coordinate: mockLocation.coordinate)
        // 2. ViewModelの準備
        let mapViewModel = MapViewModel(model: MockMapModel(), adMobModel: MockSetAdMobModel(), fetchTodayDateModel: MockFetchTodayDateModel(), commonDataModel: MockFetchCommonDataModel(), authenticationManager: MockAuthenticationManager(), firestoreService: MockFirestoreWrapper())
        // 3. Firestoreのモック
        let mockFirestore = MockFirestoreWrapper()
        mapViewModel.firestoreService = mockFirestore
        // 4. handleGeocodingResultの呼び出し
        mapViewModel.handleGeocodingResult([mockPlacemark], error: nil, forBox: mockBox)
        // 5. 結果の検証
        XCTAssert(mockFirestore.collectionCalledWith == "map_ addresses")
        XCTAssert(mockFirestore.documentCalledWith == "testID")
        XCTAssert(mockFirestore.setDataCalledWith?.data["latitude"] as? Double == 35.6895)
        XCTAssert(mockFirestore.setDataCalledWith?.data["longitude"] as? Double == 139.6917)
    }
    func testA() {
           let expectation = XCTestExpectation(description: "Geocoding complete")

           let mockFirestore = MockFirestoreWrapper()

           
           let mockAddress = [OtokuAddressModel(
               address_id: "a",
               content: "東京都中央区晴海1丁目8番16号",
               latitude: 35.6573507,
               longitude: 139.7822458
           ),OtokuAddressModel(
               address_id: "b",
               content: "住所がない",
               latitude: nil,
               longitude: nil
           ),OtokuAddressModel(
               address_id: "c",
               content: "東京都中央区晴海1丁目8番16号",
               latitude: nil,
               longitude: nil
           )]
           
           
           let mockArticle = [OtokuDataModel(
               
               address_ids: ["a"],
               article_title: "三田製麺所クーポン・キャンペーン情報",
               blog_web_url: "https://otoku-everyday.com/mitaseimen/",
               collectionView_image_url: "https://example.com/image.jpg",
               enabled_dates: ["2023-10-28"]
           ),OtokuDataModel(
               address_ids: ["b"],
               article_title: "三田製麺所クーポン・キャンペーン情報",
               blog_web_url: "https://otoku-everyday.com/mitaseimen/",
               collectionView_image_url: "https://example.com/image.jpg",
               enabled_dates: ["2023-10-28"]
           ),OtokuDataModel(
               address_ids: ["c"],
               article_title: "三田製麺所クーポン・キャンペーン情報",
               blog_web_url: "https://otoku-everyday.com/mitaseimen/",
               collectionView_image_url: "https://example.com/image.jpg",
               enabled_dates: ["2023-10-28"]
           )]
           mapViewModel.addressSubject.onNext(mockAddress)
           mapViewModel.articlesSubject.onNext(mockArticle)
           
           // ジオコーディング処理が完了するのを待つ
               DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                   expectation.fulfill()
               }

               wait(for: [expectation], timeout: 900.0)        // `handleGeocodingResult` の結果を待つ
            // ここで適切なタイムアウトを設定
                  XCTAssert(mockFirestore.documentCalledWith == "c")
                  XCTAssert(mockFirestore.setDataCalledWith?.data["latitude"] as? Double == 35.6573507)
                  XCTAssert(mockFirestore.setDataCalledWith?.data["longitude"] as? Double == 139.7822458)
           // 5. 結果の検証
   //        XCTAssert(mockFirestore.collectionCalledWith == "map_ addresses")
           
       }
   }
