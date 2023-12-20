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
    
    override func setUp() {
        super.setUp()
        slideShowSelectedIndexPath = IndexPath(row: 0, section: 0)
        scheduler = TestScheduler(initialClock: 0)
        
        mapViewModel = MapViewModel(model: mockMapModel, adMobModel: mockAdMobModel, fetchTodayDateModel: mockTodayDateModel, commonDataModel: mockCommonDataModel)
        
        disposeBag = DisposeBag()
    }
    
    override func tearDown() {
        mapViewModel = nil
        disposeBag = nil
        super.tearDown()
    }
    
    
    func testOtokuSpecialtyObservable_ShouldReturnMockData() {
        
        let expectedData = mockMapModel.mockOtokuSpecialtyData //
        let data = try! mapViewModel.otokuSpecialtyObservable.toBlocking().first()!
        XCTAssertEqual(data, expectedData)
    }
    
    func testMoveModelBoxFirstIfNeededForTodaysAnnotationModel() {
        let mockData = [
            OtokuMapModel(address: OtokuAddressModel(address_id: "1", content: "", latitude: nil, longitude: nil), article_title: "", blog_web_url: "", id: ""),
            OtokuMapModel(address: OtokuAddressModel(address_id: "2", content: "", latitude: 0.0, longitude: 0.0), article_title: "", blog_web_url: "", id: "")
        ]
        mapViewModel.setupTestDataForTest(addAnnotationRetryCount: 0, selectSegmentIndexType: 0, todaysAnnotationModel: mockData)
        
        mapViewModel.moveModelBoxFirstIfNeededForTest()
        XCTAssertFalse(mapViewModel.getTodaysAnnotationModelForTest().contains(where: { $0.address.longitude == nil }))
    }
    
    func testMoveModelBoxFirstIfNeededForAllDaysAnnotationModel() {
        let mockData = [
            OtokuMapModel(address: OtokuAddressModel(address_id: "1", content: "", latitude: nil, longitude: nil), article_title: "", blog_web_url: "", id: ""),
            OtokuMapModel(address: OtokuAddressModel(address_id: "2", content: "", latitude: 0.0, longitude: 0.0), article_title: "", blog_web_url: "", id: "")
        ]
        mapViewModel.setupTestDataForAllDaysAnnotationModelTest(addAnnotationRetryCount: 0, selectSegmentIndexType: 1, allDaysAnnotationModel: mockData)
        
        mapViewModel.moveModelBoxFirstIfNeededForTest()
        XCTAssertFalse(mapViewModel.getAllDaysAnnotationModelForTest().contains(where: { $0.address.longitude == nil }))
    }
    
    func testSlideShowCollectionViewSelectedUrlObservable() {
        
        let expectedUrl = "https://example.com"
        let mockIndexPath = IndexPath(row: 0, section: 0)
        let models = [SlideShowModel(input: ["webUrl": expectedUrl, "address": "", "title": "", "image": "", "comment": ""])]
        let mockData = models.compactMap { $0 }
        mapViewModel.otokuSpecialtySubject.onNext(mockData)
        var observedUrl: String? = nil
        let disposeBag = DisposeBag() //
        mapViewModel.output.slideShowCollectionViewSelectedUrlObservavable.subscribe(onNext: {
            observedUrl = $0
        }).disposed(by: disposeBag)
        
        mapViewModel.input.slideShowCollectionViewSelectedIndexPathObserver.onNext(mockIndexPath)
        
        XCTAssertEqual(observedUrl, expectedUrl)
    }
    
    func testViewWidthSizeSubscription() {
        let widthSizeData = SetAdMobModelData(bannerWidth: 200, bannerHight: 200, VC: UIViewController())
        mapViewModel.input.viewWidthSizeObserver.onNext(widthSizeData)
        XCTAssertEqual(mockAdMobModel.setAdMobCalledWith?.bannerWidthSize, 200)
    }
    
    func testFetchMapAllDataTriggerSubscription() {
        mapViewModel.input.fetchMapAllDataTriggerObserver.onNext(())
        XCTAssertTrue(mockMapModel.fetchOtokuSpecialtyDataCalled)
    }
    
    func testOtokuSpecialtyObservableSubscription() {
        
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
        let disposeBag = DisposeBag() //
        mapViewModel.output.slideShowCollectionViewSelectedUrlObservavable.subscribe(onNext: {
            observedUrl = $0
        }).disposed(by: disposeBag)
        mapViewModel.input.slideShowCollectionViewSelectedIndexPathObserver.onNext(IndexPath(row: 0, section: 0))
        XCTAssertEqual(observedUrl, expectedUrl)
    }
    
    func testForegroundJudge() {
        let observer = scheduler.createObserver(Bool.self)
        mapViewModel.foregroundJudge
            .bind(to: observer)
            .disposed(by: disposeBag)
        mapViewModel.foregroundJudgeRelay.onNext(true)
        XCTAssertEqual(observer.events, [.next(0, true), .next(0, true)])
    }
    
    func testLocationStatus() {
        let observer = scheduler.createObserver(CLAuthorizationStatus.self)
        mapViewModel.LocationStatus
            .bind(to: observer)
            .disposed(by: disposeBag)
        let expectedStatus = CLAuthorizationStatus.authorizedAlways
        mapViewModel.userLocationStatusRelay.onNext(expectedStatus)
        XCTAssertEqual(observer.events, [.next(0, expectedStatus)])
    }
    
    func testDidEnterBackground() {
        let observer = scheduler.createObserver(Bool.self)
        mapViewModel.didEnterBackground.bind(to: observer).disposed(by: disposeBag)
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        XCTAssertEqual(observer.events, [Recorded.next(0, false)])
    }
    
    func testWillEnterForeground() {
        let observer = scheduler.createObserver(Bool.self)
        mapViewModel.willEnterForeground.bind(to: observer).disposed(by: disposeBag)
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        XCTAssertEqual(observer.events, [Recorded.next(0, true)])
    }
    
    func testArticleObserver() {
        let initialData = try! mapViewModel.articlesSubject.value()
        XCTAssertEqual(initialData, [])
        let testData = [
            OtokuDataModel(
                address_ids: ["address1", "address2"],
                article_title: "Test Article Title",
                blog_web_url: "https://example.com/blog",
                collectionView_image_url: "https://example.com/image.jpg",
                enabled_dates: ["2023-10-01", "2023-10-02"]
            )
        ]
        mapViewModel.articleObserver.onNext(testData)
        let newData = try! mapViewModel.articlesSubject.value()
        XCTAssertEqual(newData, testData)
    }
    
    func testProcessBoxGeocoding() {
        let expectedPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917))
        let mockGeocoder = MockGeocoder(result: expectedPlacemark, error: nil)
        mapViewModel.addressGeocoder = mockGeocoder
        let mockFirestore = MockFirestore()
        mapViewModel.db = mockFirestore
        let testAddress = OtokuAddressModel(address_id: "testID", content: "Test Address", latitude: nil, longitude: nil)
        let testBox = OtokuMapModel(address: testAddress, article_title: "Test", blog_web_url: "https://test.com", id: "testID")
        mapViewModel.processBox(testBox)
        if let savedData = mockFirestore.setDataCalledWith,
           let savedLatitude = savedData["latitude"] as? Double,
           let savedLongitude = savedData["longitude"] as? Double {
            XCTAssertEqual(savedLatitude, 35.6895)
            XCTAssertEqual(savedLongitude, 139.6917)
        } else {
            XCTFail("Expected latitude and longitude values were not found in setDataCalledWith.")
        }
    }
    
    func testModelBoxObservable() {
        mapViewModel.currentSegmente.accept(.all)
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
        let mockPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917))
        let mockGeocoder = MockGeocoder(result: mockPlacemark, error: nil)
        mapViewModel.addressGeocoder = mockGeocoder
        let mockFirestore = MockFirestore()
        mapViewModel.db = mockFirestore
        
        mapViewModel.addressSubject.onNext([mockAddress])
        mapViewModel.articlesSubject.onNext([mockArticle])
        
        XCTAssert(mockFirestore.collectionCalledWith == "map_ addresses")
        XCTAssert(mockFirestore.documentCalledWith == "testID")
        XCTAssert(mockFirestore.setDataCalledWith?["latitude"] as? Double == 35.6895)
        XCTAssert(mockFirestore.setDataCalledWith?["longitude"] as? Double == 139.6917)
    }
    
    func testHandleGeocodingResult() {
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
        
        let mapViewModel = MapViewModel(model: MockMapModel(), adMobModel: MockSetAdMobModel(), fetchTodayDateModel: MockFetchTodayDateModel(), commonDataModel: MockFetchCommonDataModel())
        
        let mockFirestore = MockFirestore()
        mapViewModel.db = mockFirestore
        
        mapViewModel.handleGeocodingResult([mockPlacemark], error: nil, forBox: mockBox)
        
        XCTAssert(mockFirestore.collectionCalledWith == "map_ addresses")
        XCTAssert(mockFirestore.documentCalledWith == "testID")
        XCTAssert(mockFirestore.setDataCalledWith?["latitude"] as? Double == 35.6895)
        XCTAssert(mockFirestore.setDataCalledWith?["longitude"] as? Double == 139.6917)
    }
}


