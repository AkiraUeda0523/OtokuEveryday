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

protocol MapViewModelInput {//ステイトとセグメントスライドの二つを内包
    var articleObserver: AnyObserver<[OtokuDataModel]> { get }
    var addressObserver: AnyObserver<[OtokuAddressModel]> { get }
    var currentSegmente: BehaviorRelay<MapViewController.SegmentedType> { get }//注
    //-------------------------------------------------------------------ステータス
//    var foregroundJudgeRelay: BehaviorSubject<Bool> { get }
//    var currentlyDisplayedVCRelay: BehaviorSubject<Bool>{ get }
//    var userLocationStatusRelay: PublishSubject<CLAuthorizationStatus>{ get }
//    var didEnterBackgroundSubject: BehaviorSubject<Bool>{ get }
//    var willEnterForegroundSubject: BehaviorSubject<Bool>{ get }

    var foregroundJudge: Observable<Bool> { get }
    var currentlyDisplayed: Observable<Bool> { get }
    var LocationStatus: Observable<CLAuthorizationStatus> { get }
    var didEnterBackground:Observable<Bool> { get }
    var willEnterForeground:Observable<Bool> { get }
    //-------------------------------------------------------------------------------

    var viewWidthSizeObserver: AnyObserver<SetAdMobModelData> { get }
    var slideShowCollectionViewSelectedIndexPathObserver: AnyObserver<IndexPath> { get }
    var fetchMapAllDataTriggerObserver:AnyObserver<Void> { get }
}
//-------------------------------------------------------------------------------
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
final class MapViewModel{//テストとはinput走らせてoutput発火するか。それだけ　　シングルトン、Auth、復旧ロジック
    //--------------------------------------------------------------------------
    var foregroundJudgeRelay = BehaviorSubject<Bool>(value: true)
    var currentlyDisplayedVCRelay = BehaviorSubject<Bool>(value: false)
    var userLocationStatusRelay = PublishSubject<CLAuthorizationStatus>()
    var didEnterBackgroundSubject = BehaviorSubject<Bool>(value: false)
    var willEnterForegroundSubject = BehaviorSubject<Bool>(value: true)
    var SetAdMobModelRelay = PublishRelay<GADBannerView>()
    var viewWidthSizeSubject = PublishSubject<SetAdMobModelData>()
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
    let disposeBag = DisposeBag()
    // Initializer
    init(model: MapModelType,adMobModel: SetAdMobModelType,fetchTodayDateModel: FetchTodayDateModelType) {
        todayDateModel = fetchTodayDateModel
        mapModel = model
        setAdMobModel = adMobModel

        //viewからWidthSizeの通知待ち（AdMob）
        viewWidthSizeSubject
            .subscribe { [self] size in
                setAdMobModel.setAdMob(viewWidthSize: size.element?.size ?? 0, Self: size.element!.VC)
            }
            .disposed(by: disposeBag)
        //AdMob出来上がりをViewへ
        setAdMobModel
            .output
            .SetAdMobModelObservable
            .subscribe { [self] setAdMob in
                SetAdMobModelRelay.accept(setAdMob)
            }
            .disposed(by: disposeBag)
        //データ取得の総まとめトリガー
        fetchMapAllDataTrigger
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                mapModel.input.fetchOtokuSpecialtyData()//SliderCellのコンテントモード要らないんじゃね？
                mapModel.input.fetchAllOtokuDataFromRealTimeDB()
                mapModel.input.fetchAddressDataFromRealTimeDB()
                //        let today = GetDateModel.gatToday()
                todayRelay.accept(todayDateModel.input.fetchTodayDate())
            })
            .disposed(by: disposeBag)
        //スライドビュー用データ
        mapModel
            .output
            .otokuSpecialtyObservable
            .subscribe { [self] data in
                otokuSpecialtySubject
                    .onNext(data)
            }
            .disposed(by: disposeBag)
        //アドレスデータ
        mapModel
            .output
            .AddressDataObservable
            .subscribe { [self] address in
                addressSubject.onNext(address)
            }
            .disposed(by: disposeBag)
        //総合データ
        mapModel
            .output
            .AllOtokuDataObservable
            .subscribe{[self] data in
                articlesSubject.onNext(data)
            }
            .disposed(by: disposeBag)

        //currentSegmenteを監視して実際のデータ切り替え
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
        //当日pin
        mapTodaysModelObservable
            .subscribe(onNext: { [weak self] todayArticle in
                self?.todaysAnnotationModel.accept(todayArticle)
            })
            .disposed(by: disposeBag)
        //全てのpin
        mapModelsObservable
            .subscribe(onNext: { [weak self] todayArticle in
                self?.allDaysAnnotationModel.accept(todayArticle)
            })
            .disposed(by: disposeBag)

        // Geocoder
        modelBoxObservable//⭐️⭐️登録用
            .map { boxs in
                boxs.filter { $0.address.longitude == nil || $0.address.latitude == nil }//要らんかも？回ってるかも？
            }
        //            .debug("デバッグ")
            .compactMap(\.first)
            .subscribe(onNext: { [weak self] box in
                guard let content = box.address.content, !content.isEmpty else {
                    self?.moveModelBoxFirstIfNeeded()
                    return
                }
                sleep(5)
                self?.addressGeocoder.geocodeAddressString(content) { [weak self] placemarks, error in
                    guard error == nil, let coordinate = placemarks?.first?.location?.coordinate else {
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

        //------------------------------------------------------------------------
        //全てデータの緯度経度あるモノのみ
        modelBoxObservable//共通表示用
            .map { boxs in//型推論省略
                boxs.filter { $0.address.longitude != nil && $0.address.latitude != nil }
            }
        //            .filter{models in
        //                let adresses = models.map(\.address.longitude)
        //                return !adresses.contains(where: {$0 == nil})
        //            }//ここで切ってretune 下をVCでサブスク
        //            .distinctUntilChanged()//状態変化無しを無視
            .subscribe(onNext: { [self] boxs in
                modelBoxRelay.accept(boxs)
            })
            .disposed(by: disposeBag)

        //--------------------------------------------------------------------------
        //スライドtap時の遷移用URL
        Observable
            .combineLatest(slideShowCollectionViewSelectedIndexPathSubject.asObserver(),otokuSpecialtySubject.asObservable())
            .map {  indexPath, data in
                let selectedUrl =  data[indexPath.row].webUrl
                return selectedUrl
            }
            .bind(to: slideShowCollectionViewSelectedUrlSubject)
            .disposed(by: disposeBag)

        //foreground監視用
        let foregroundJudge = Observable.of(didEnterBackgroundSubject, willEnterForegroundSubject).merge().startWith(true)
    }
    //init最終---------------------------------
    //state関係の最終ジャッジ
    var isShow: Observable<Bool> {
        return Observable.combineLatest(foregroundJudge,currentlyDisplayedVCRelay) {
            $0 == true && $1 == true
        }
    }

    //配列の後ろに回す実質ループメソッド
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
    //foreground監視用２？
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
//class最終---------------------------------
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
    //MARK: -ステイト
    var foregroundJudge: Observable<Bool> {
        return  foregroundJudgeRelay.asObservable()//ノーティフィ
    }
    var currentlyDisplayed: Observable<Bool> {//タブバーコントローラー
        return currentlyDisplayedVCRelay.asObservable()
    }
    var LocationStatus: Observable<CLAuthorizationStatus> {//ステータスをアペンド
        return userLocationStatusRelay.asObservable()
    }
    var didEnterBackground:Observable<Bool> {//ファンクション？
        return NotificationCenter.default.rx.notification(UIApplication.didEnterBackgroundNotification)
            .map { _ in false }
    }
    var willEnterForeground:Observable<Bool>{//ファンクション？
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
    //当日分絞り込み？
    var todayInfosObservable: Observable<[OtokuDataModel]> {
        Observable.combineLatest(todayRelay,articlesSubject)
            .map { selectDate, data in
                data.filter {
                    $0.enabled_dates.contains(selectDate)
                }
            }
    }
    //Map用当日データの完成
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
                .convertOtokuMapModel(article: article)
            }
        }
    }
    //Map用全データの完成
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
//MARK: -Map用のモデルへ変換雛形
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
