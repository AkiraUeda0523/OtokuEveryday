////
////  MapViewModel.swift
////  RedMoon2021
////
////  Created by 上田晃 on 2022/09/16.
////
import Foundation
import RxSwift
import RxRelay
import MapKit
import GoogleMobileAds
import FirebaseFirestore

protocol MapViewModelInput {
    var articleObserver: AnyObserver<[OtokuDataModel]> { get }
    var addressObserver: AnyObserver<[OtokuAddressModel]> { get }
    var currentSegmente: BehaviorRelay<MapViewController.SegmentedType> { get }
    var foregroundJudgeRelay: BehaviorSubject<Bool> { get }
    var userLocationStatusRelay: PublishSubject<CLAuthorizationStatus>{ get }
    var foregroundJudge: Observable<Bool> { get }
    var LocationStatus: Observable<CLAuthorizationStatus> { get }
    var viewWidthSizeObserver: AnyObserver<SetAdMobModelData> { get }
    var slideShowCollectionViewSelectedIndexPathObserver: AnyObserver<IndexPath> { get }
    var fetchMapAllDataTriggerObserver:AnyObserver<Void> { get }
}

protocol MapViewModelOutput {
    var mapTodaysModelObservable:Observable<[OtokuMapModel]> { get }
    var mapModelsObservable:Observable<[OtokuMapModel]> { get }
    var todayInfosObservable: Observable<[OtokuDataModel]> { get }
    var modelBoxObservable: Observable<[OtokuMapModel]> { get }
    var SetAdMobModelObservable: Observable<GADBannerView> { get }
    var otokuSpecialtyObservable: Observable<[SlideShowModel]> { get }
    var slideShowCollectionViewSelectedUrlObservavable: Observable<String> { get }
}

protocol MapViewModelType {
    var input: MapViewModelInput { get }
    var output: MapViewModelOutput { get }
}

enum SegmentedType: Int {
    case today
    case all
}

// MARK: -
final class MapViewModel{
    var foregroundJudgeRelay = BehaviorSubject<Bool>(value: true)
    var userLocationStatusRelay = PublishSubject<CLAuthorizationStatus>()
    var SetAdMobModelRelay = PublishRelay<GADBannerView>()
    var viewWidthSizeSubject = PublishSubject<SetAdMobModelData>()
    private var addAnnotationRetryCount = 0
    private var selectSegmentIndexType:Int = 0
    internal var addressGeocoder: AddressGeocoder = CLGeocoder()
    private var status = CLLocationManager.authorizationStatus()
    internal var db:FirestoreProtocol = Firestore.firestore()
    private let allDaysAnnotationModel = BehaviorRelay<[OtokuMapModel]>(value: [])
    private let todaysAnnotationModel = BehaviorRelay<[OtokuMapModel]>(value: [])
    //input
    let articlesSubject = BehaviorSubject<[OtokuDataModel]>(value: [])
    let addressSubject = BehaviorSubject<[OtokuAddressModel]>(value: [])
    let currentSegmente = BehaviorRelay<MapViewController.SegmentedType>(value: .today)
    let slideShowCollectionViewSelectedIndexPathSubject = PublishSubject<IndexPath>()
    var fetchMapAllDataTrigger = PublishSubject<Void>()
    //output
    let todayRelay = BehaviorRelay<String>(value: "")
    let modelBoxRelay = BehaviorRelay<[OtokuMapModel]>(value: [])
    let otokuSpecialtySubject = BehaviorSubject<[SlideShowModel]>(value: [])
    let slideShowCollectionViewSelectedUrlSubject = PublishSubject<String>()
    let todayDateModel: FetchTodayDateModelType
    let mapModel: MapModelType
    let setAdMobModel: SetAdMobModelType
    let CommonDataModel: FetchCommonDataModelType
    let disposeBag = DisposeBag()
    
    init(model: MapModelType, adMobModel: SetAdMobModelType, fetchTodayDateModel: FetchTodayDateModelType, commonDataModel: FetchCommonDataModelType) {
        todayDateModel = fetchTodayDateModel
        mapModel = model
        setAdMobModel = adMobModel
        CommonDataModel = commonDataModel
        
        viewWidthSizeSubject
            .subscribe { [self] size in
                setAdMobModel.setAdMob(bannerWidthSize: size.element?.bannerWidth ?? 0, bannerHight: size.element?.bannerHight ?? 0, viewController: size.element!.VC)
            }
            .disposed(by: disposeBag)
        
        setAdMobModel
            .output
            .SetAdMobModelObservable
            .subscribe { [self] (setAdMob: AdBannerView) in
                SetAdMobModelRelay.accept(setAdMob as! GADBannerView)
            }
            .disposed(by: disposeBag)
        
        mapModel.input.fetchOtokuSpecialtyData()
        mapModel.input.fetchAddressDataFromRealTimeDB()
        todayRelay.accept(todayDateModel.input.fetchTodayDate())
        
        mapModel
            .output
            .otokuSpecialtyObservable
            .subscribe { [self] data in
                otokuSpecialtySubject
                    .onNext(data)
            }
            .disposed(by: disposeBag)
        
        mapModel
            .output
            .AddressDataObservable
            .subscribe { [self] address in
                addressSubject.onNext(address)
            }
            .disposed(by: disposeBag)
        
        CommonDataModel
            .output
            .fetchCommonDataModelObservable
            .subscribe{[self] data in
                articlesSubject.onNext(data)
            }
            .disposed(by: disposeBag)
        
        CommonDataModel
            .output
            .shouldUpdateDataObservable
            .subscribe { [self] judge in
                mapModel.input.shouldUpdateDataJudgeObserver.onNext(judge)
            }
            .disposed(by: disposeBag)
        
        mapTodaysModelObservable
            .subscribe(onNext: { [weak self] todayArticle in
                self?.todaysAnnotationModel.accept(todayArticle)
            })
            .disposed(by: disposeBag)
        
        mapModelsObservable
            .subscribe(onNext: { [weak self] allArticle in
                self?.allDaysAnnotationModel.accept(allArticle)
            })
            .disposed(by: disposeBag)
        // MARK: -
        let  modelBoxObservableFromSegment = currentSegmente
            .withUnretained(self)
            .flatMap { weakSelf, type -> Observable<[OtokuMapModel]> in
                switch type {
                    
                case .today:
                    self.addAnnotationRetryCount = 0
                    return weakSelf.mapTodaysModelObservable.asObservable()
                    
                case .all:
                    self.addAnnotationRetryCount = 0
                    return weakSelf.mapModelsObservable.asObservable()
                }
            }
            .share(replay: 1)
        
        modelBoxObservableFromSegment
            .map { mapModels in
                mapModels.filter { $0.address.longitude == nil || $0.address.latitude == nil }
            }
            .compactMap(\.first)
            .subscribe(onNext: { [weak self] incompleteCoordinates in
                self?.processBox(incompleteCoordinates)
            })
            .disposed(by: disposeBag)
        
        modelBoxObservableFromSegment
            .map { mapModels in
                mapModels.filter { $0.address.longitude != nil && $0.address.latitude != nil }
            }
            .subscribe(onNext: { [self] validCoordinates in
                modelBoxRelay.accept(validCoordinates)
            })
            .disposed(by: disposeBag)
        
        // MARK: -
        slideShowCollectionViewSelectedIndexPathSubject
            .withLatestFrom(otokuSpecialtySubject) { indexPath, data in
                let selectedUrl = data[indexPath.row].webUrl
                return selectedUrl
            }
            .bind(to: slideShowCollectionViewSelectedUrlSubject)
            .disposed(by: disposeBag)
    }
    
    // MARK: -functions
    
    func processBox(_ box: OtokuMapModel) {
        guard let content = box.address.content, !content.isEmpty else {
            moveModelBoxFirstIfNeeded()
            return
        }
        sleep(5)
        
        addressGeocoder.geocodeAddressString(content) { [weak self] placemarks, error in
            self?.handleGeocodingResult(placemarks, error: error, forBox: box)
        }
    }
    
    func handleGeocodingResult(_ placemarks: [CLPlacemark]?, error: Error?, forBox box: OtokuMapModel) {
        guard error == nil, let coordinate = placemarks?.first?.location?.coordinate else {
            moveModelBoxFirstIfNeeded()
            return
        }
        db.collectionPath("map_ addresses")
            .documentPath(box.id)
            .setData(
                [
                    "latitude": coordinate.latitude as Any,
                    "longitude": coordinate.longitude as Any
                ],
                merge: true
            ) { [weak self] (err: Error?) in
                if err != nil {
                    self?.moveModelBoxFirstIfNeeded()
                }
            }
    }
    
    private func moveModelBoxFirstIfNeeded() {
        if self.addAnnotationRetryCount < 500 && self.selectSegmentIndexType == 0{
            self.addAnnotationRetryCount += 1
            let currentValue = todaysAnnotationModel.value
            guard currentValue.count >= 2 , let removeId = currentValue.first(where: {$0.address.longitude == nil})
                .map(\.id)
            else { return }
            let result: [OtokuMapModel] = currentValue.filter{$0.id != removeId}
            todaysAnnotationModel.accept(result)
        } else if self.addAnnotationRetryCount < 500 && self.selectSegmentIndexType == 1{
            self.addAnnotationRetryCount += 1
            let currentValue = allDaysAnnotationModel.value
            guard currentValue.count >= 2 , let removeId = currentValue.first(where: {$0.address.longitude == nil})
                .map(\.id)
            else { return }
            let result: [OtokuMapModel] = currentValue.filter{$0.id != removeId}
            allDaysAnnotationModel.accept(result)
        }
    }
    func setupTestDataForTest(addAnnotationRetryCount: Int, selectSegmentIndexType: Int, todaysAnnotationModel: [OtokuMapModel]) {
        self.addAnnotationRetryCount = addAnnotationRetryCount
        self.selectSegmentIndexType = selectSegmentIndexType
        self.todaysAnnotationModel.accept(todaysAnnotationModel)
    }
    
    func moveModelBoxFirstIfNeededForTest() {
        self.moveModelBoxFirstIfNeeded()
    }
    
    func getTodaysAnnotationModelForTest() -> [OtokuMapModel] {
        return self.todaysAnnotationModel.value
    }
    func setupTestDataForAllDaysAnnotationModelTest(addAnnotationRetryCount: Int, selectSegmentIndexType: Int, allDaysAnnotationModel: [OtokuMapModel]) {
        self.addAnnotationRetryCount = addAnnotationRetryCount
        self.selectSegmentIndexType = selectSegmentIndexType
        self.allDaysAnnotationModel.accept(allDaysAnnotationModel)
    }
    
    func getAllDaysAnnotationModelForTest() -> [OtokuMapModel] {
        return self.allDaysAnnotationModel.value
    }
}
//MARK: -extension　Type
extension MapViewModel: MapViewModelType {
    var input: MapViewModelInput { return self }
    var output: MapViewModelOutput { return self }
}
//MARK: -extension　Input
extension MapViewModel: MapViewModelInput{
    var fetchMapAllDataTriggerObserver: RxSwift.AnyObserver<Void> {
        fetchMapAllDataTrigger.asObserver()
    }
    var slideShowCollectionViewSelectedIndexPathObserver: AnyObserver<IndexPath> {
        return slideShowCollectionViewSelectedIndexPathSubject.asObserver()
    }
    var articleObserver: AnyObserver<[OtokuDataModel]> {
        return articlesSubject.asObserver()
    }
    var addressObserver: AnyObserver<[OtokuAddressModel]> {
        return  addressSubject.asObserver()
    }
    var viewWidthSizeObserver: RxSwift.AnyObserver<SetAdMobModelData> {
        return viewWidthSizeSubject.asObserver()
    }
    
    var foregroundJudge: Observable<Bool> {
        return  foregroundJudgeRelay.asObservable()
    }
    var LocationStatus: Observable<CLAuthorizationStatus> {
        return userLocationStatusRelay.asObservable()
    }
    var didEnterBackground:Observable<Bool> {
        return NotificationCenter.default.rx.notification(UIApplication.didEnterBackgroundNotification)
            .map { _ in false }
    }
    var willEnterForeground:Observable<Bool>{
        return  NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification)
            .map { _ in true }
    }
}
//MARK: -extension　Output
extension MapViewModel: MapViewModelOutput{
    var slideShowCollectionViewSelectedUrlObservavable: Observable<String> {
        return slideShowCollectionViewSelectedUrlSubject.asObservable()
    }
    var otokuSpecialtyObservable: Observable<[SlideShowModel]> {
        return otokuSpecialtySubject.asObservable()
    }
    var SetAdMobModelObservable: Observable<GADBannerView> {
        return SetAdMobModelRelay.asObservable()
    }
    var modelBoxObservable: Observable<[OtokuMapModel]> {
        return modelBoxRelay.asObservable()
    }
    var todayInfosObservable: Observable<[OtokuDataModel]> {
        Observable.combineLatest(todayRelay,articlesSubject)
            .map { selectDate, data in
                data.filter {
                    $0.enabled_dates.contains(selectDate)
                }
            }
    }
    var mapTodaysModelObservable:Observable<[OtokuMapModel]>{
        Observable.combineLatest(
            addressSubject,
            todayInfosObservable
        )
        .map { address, info -> [OtokuMapModel] in info[OtokuDataModel]
            info.flatMap { article -> [OtokuMapModel] in
                article.address_ids.compactMap {  id -> OtokuAddressModel? ing
                    address.first(where: { $0.address_id == id })/
                }
                .convertOtokuMapModel(article: article)
            }
        }
    }
    
    var mapModelsObservable:Observable<[OtokuMapModel]>{
        Observable.combineLatest(
            addressSubject,
            articlesSubject
        )
        .map { address, info -> [OtokuMapModel] in
            var result = [OtokuMapModel]()
            info.map { article -> [OtokuMapModel] in
                article.address_ids.compactMap {  id -> OtokuAddressModel? in
                    guard let address = address.first(where: { $0.address_id == id }) else {
                        return nil
                    }
                    return address
                }
                .map{  address -> OtokuMapModel in
                    OtokuMapModel(address: address, article_title: article.article_title, blog_web_url: article.blog_web_url, id: address.address_id)
                }
            }
            .forEach { models in
                models.forEach { model in
                    result.append(model)
                }
            }
            return result
        }
    }
}
//MARK: -
extension Array where Element == OtokuAddressModel {
    func convertOtokuMapModel(article: OtokuDataModel) -> [OtokuMapModel] {
        map { address in
            OtokuMapModel(
                address: address,
                article_title: article.article_title,
                blog_web_url: article.blog_web_url,
                id: address.address_id
            )
        }
    }
}

//MARK: -
extension Firestore: FirestoreProtocol {
    func collectionPath(_ path: String) -> FirestoreProtocol {
        
        return self // 一時的な実装として
    }
    
    func documentPath(_ path: String) -> DocumentReferenceProtocol {
        // Firestoreのdocumentメソッドを使用してDocumentReferenceを取得し、適切にキャストする。
        return self.document(path) as DocumentReferenceProtocol
    }
    
    func actualSetData(_ data: [String : Any], merge: Bool, completion: ((Error?) -> Void)?) {
    }//現状使っていない
}

extension DocumentReference: DocumentReferenceProtocol {
    func setData(_ documentData: [String : Any], merge: Bool, completion: ((Error?) -> Void)?) {
        self.setData(documentData, merge: merge, completion: completion)
    }
}

extension CLGeocoder: AddressGeocoder {}

