//
//  MapViewModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2023/01/10.
//

import Foundation
import RxSwift
import RxRelay
import MapKit
import FirebaseFirestore

protocol MapViewModelInput {
    var articleObserver: AnyObserver<[OtokuDataModel]> { get }
    var addressObserver: AnyObserver<[OtokuAddressModel]> { get }
    var currentSegmente: BehaviorRelay<MapViewController.SegmentedType> { get }//注
    //--------------------------------------------------------------------------------
    var foregroundJudgeRelay: BehaviorSubject<Bool> { get }
    var currentlyDisplayedVCRelay: BehaviorSubject<Bool>{ get }
    var userLocationStatusRelay: PublishSubject<CLAuthorizationStatus>{ get }
    var didEnterBackgroundSubject: BehaviorSubject<Bool>{ get }
    var willEnterForegroundSubject: BehaviorSubject<Bool>{ get }

    var foregroundJudge: Observable<Bool> { get }
    var currentlyDisplayed: Observable<Bool> { get }
    var LocationStatus: Observable<CLAuthorizationStatus> { get }
    var didEnterBackground:Observable<Bool> { get }
    var willEnterForeground:Observable<Bool> { get }
}
//-------------------------------------------------------------------------------
protocol MapViewModelOutput {
    var mapTodaysModelObservable:Observable<[OtokuMapModel]> { get }
    var mapModelsObservable:Observable<[OtokuMapModel]> { get }
    var todayInfosObservable: Observable<[OtokuDataModel]> { get }
    var modelBoxObservable: Observable<[OtokuMapModel]> { get }
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
    //--------------------------------------------------------------------------
    var foregroundJudgeRelay = BehaviorSubject<Bool>(value: true)
    var currentlyDisplayedVCRelay = BehaviorSubject<Bool>(value: false)
    var userLocationStatusRelay = PublishSubject<CLAuthorizationStatus>()
    var didEnterBackgroundSubject = BehaviorSubject<Bool>(value: false)
    var willEnterForegroundSubject = BehaviorSubject<Bool>(value: true)
    //--------------------------------------------------------------------------

    private var addAnnotationRetryCount = 0
    private var selectSegmentIndexType:Int = 0

    private let addressGeocoder = CLGeocoder()
    private var status = CLLocationManager.authorizationStatus()
    private var db = Firestore.firestore()

    private let allDaysAnnotationModel = BehaviorRelay<[OtokuMapModel]>(value: [])//⭐️
    private let todaysAnnotationModel = BehaviorRelay<[OtokuMapModel]>(value: [])
    //input
    let articlesSubject = BehaviorSubject<[OtokuDataModel]>(value: [])
    let addressSubject = BehaviorSubject<[OtokuAddressModel]>(value: [])
    let currentSegmente = BehaviorRelay<MapViewController.SegmentedType>(value: .today)
    //output
    let todayRelay = BehaviorRelay<String>(value: "")
    let modelBoxRelay = BehaviorRelay<[OtokuMapModel]>(value: [])

    let mapModel: MapModelType
    let disposeBag = DisposeBag()

    // Initializer
    init(model: MapModelType) {

        mapModel = model
        mapModel.input.fetchAllOtokuDataFromRealTimeDB()
        mapModel.input.fetchAddressDataFromRealTimeDB()

        let today = GetDateModel.gatToday()
        todayRelay.accept(today)

        mapModel
            .output
            .AddressDataObservable
            .subscribe { [self] address in
                addressSubject.onNext(address)
            }
            .disposed(by: disposeBag)

        mapModel
            .output
            .AllOtokuDataObservable
            .subscribe{[self] data in
                articlesSubject.onNext(data)
            }
            .disposed(by: disposeBag)

        let modelBoxObservable = currentSegmente
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
            .share(replay: 1)//Hot変換

        mapTodaysModelObservable
            .subscribe(onNext: { [weak self] todayArticle in
                self?.todaysAnnotationModel.accept(todayArticle)
            })
            .disposed(by: disposeBag)

        mapModelsObservable
            .subscribe(onNext: { [weak self] todayArticle in
                self?.allDaysAnnotationModel.accept(todayArticle)
            })
            .disposed(by: disposeBag)
        // MARK: -VM
        modelBoxObservable
            .map { boxs in
                boxs.filter { $0.address.longitude == nil || $0.address.latitude == nil }
            }
            .debug("デバッグ")
            .compactMap(\.first)
            .subscribe(onNext: { [weak self] box in
                guard let content = box.address.content, !content.isEmpty else {
                    self?.moveModelBoxFirstIfNeeded()
                    return
                }
                sleep(5)
                self?.addressGeocoder.geocodeAddressString(content) { [weak self] placemarks, error in
                    guard error == nil, let coordinate = placemarks?.first?.location?.coordinate else {
                        var testBox = []
                        let errorID = box.id
                        testBox.append(errorID)
                        self?.moveModelBoxFirstIfNeeded()
                        return
                    }
                    self?.db.collection("map_ addresses")
                        .document(box.id)
                        .setData(
                            [
                                "latitude": coordinate.latitude as Any,
                                "longitude": coordinate.longitude as Any
                            ],
                            merge: true
                        ) { err in
                            if err != nil {
                                self?.moveModelBoxFirstIfNeeded()
                            }
                        }
                }
            })
            .disposed(by: disposeBag)
        // MARK: -VM
        modelBoxObservable//共通表示用
            .map { boxs in//型推論省略
                boxs.filter { $0.address.longitude != nil && $0.address.latitude != nil }
            }
            .filter{models in
                let adresses = models.map(\.address.longitude)
                return !adresses.contains(where: {$0 == nil})
            }
            .subscribe(onNext: { [self] boxs in
                modelBoxRelay.accept(boxs)
            })
            .disposed(by: disposeBag)

        let foregroundJudge = Observable.of(didEnterBackgroundSubject, willEnterForegroundSubject).merge().startWith(true)
    }
    var isShow: Observable<Bool> {
        return Observable.combineLatest(foregroundJudge,currentlyDisplayedVCRelay) {
            $0 == true && $1 == true
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
    // MARK: -ステイト関係
    private func bindInput() {// status
        NotificationCenter.default.rx.notification(UIApplication.willResignActiveNotification)
            .subscribe(onNext: { [unowned self] _ in
                // アプリがアクティブではなくなる時
                foregroundJudgeRelay.onNext(false)
            })
            .disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
            .subscribe(onNext: { [unowned self] _ in
                // アプリがアクティブになった時
                foregroundJudgeRelay.onNext(true)
            })
            .disposed(by: disposeBag)
    }
}
//MARK: -extension　Type
extension MapViewModel: MapViewModelType {
    var input: MapViewModelInput { return self }
    var output: MapViewModelOutput { return self }
}
//MARK: -extension　Input
extension MapViewModel: MapViewModelInput{
    var articleObserver: AnyObserver<[OtokuDataModel]> {
        return articlesSubject.asObserver()
    }
    var addressObserver: AnyObserver<[OtokuAddressModel]> {
        return  addressSubject.asObserver()
    }
    //MARK: -ステイト
    var foregroundJudge: Observable<Bool> {
        return  foregroundJudgeRelay.asObservable()
    }
    var currentlyDisplayed: Observable<Bool> {
        return currentlyDisplayedVCRelay.asObservable()
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
    var modelBoxObservable: RxSwift.Observable<[OtokuMapModel]> {
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
        .map { address, info -> [OtokuMapModel] in
            info.flatMap { article -> [OtokuMapModel] in
                article.address_ids.compactMap {  id -> OtokuAddressModel? in
                    address.first(where: { $0.address_id == id })
                }
                .convertOtokuMapModel2(article: article)
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
    func convertOtokuMapModel2(article: OtokuDataModel) -> [OtokuMapModel] {
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
