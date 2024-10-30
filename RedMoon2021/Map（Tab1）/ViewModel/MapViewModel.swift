////
////  MapViewModel.swift
////  RedMoon2021
////
////  Created by 上田晃 on 2022/09/16.
///
import RxSwift
import RxRelay
import MapKit
import GoogleMobileAds
import Firebase
import RealmSwift
// MARK: - Protocols
protocol MapViewModelInput {
    var viewWidthSizeObserver: AnyObserver<SetAdMobModelData> { get }
    var slideShowCollectionViewSelectedIndexPathObserver: AnyObserver<IndexPath> { get }
}
protocol MapViewModelOutput {
    var mapTodaysModelObservable: Observable<[OtokuMapModel]> { get }
    var mapModelsObservable: Observable<[OtokuMapModel]> { get }
    var SetAdMobModelObservable: Observable<GADBannerView> { get }
    var otokuSpecialtyObservable: Observable<[SlideShowModel]> { get }
    var slideShowCollectionViewSelectedUrlObservavable: Observable<String> { get }
}
protocol MapViewModelType {
    var input: MapViewModelInput { get }
    var output: MapViewModelOutput { get }
}
// MARK: - Main Class
final class MapViewModel {
    var SetAdMobModelRelay = PublishRelay<GADBannerView>()//UI?
    var viewWidthSizeSubject = PublishSubject<SetAdMobModelData>()
    
    private var addAnnotationRetryCount = 0
    internal var addressGeocoder: AddressGeocoder = CLGeocoder()
    
    let articlesSubject = BehaviorSubject<[OtokuDataModel]>(value: [])
    let addressSubject = BehaviorSubject<[OtokuAddressModel]>(value: [])
    let slideShowCollectionViewSelectedIndexPathSubject = PublishSubject<IndexPath>()
    let todayRelay = BehaviorRelay<String>(value: "")//UI?
    let otokuSpecialtySubject = BehaviorSubject<[SlideShowModel]>(value: [])
    let slideShowCollectionViewSelectedUrlSubject = PublishSubject<String>()
    var todayInfosObservable: Observable<[OtokuDataModel]> {
        return Observable.combineLatest(todayRelay, articlesSubject)
            .map { selectDate, data in
                data.filter { $0.enabled_dates.contains(selectDate) }
            }
    }
    // MARK: -init
    let todayDateModel: FetchTodayDateModelType
    let mapModel: MapModelType
    let setAdMobModel: SetAdMobModelType
    let CommonDataModel: FetchCommonDataModelType
    let AuthenticationManager: AuthenticationManagerType
    let firestoreService: FirestoreWrapperProtocol
    let disposeBag = DisposeBag()
    init(model: MapModelType, adMobModel: SetAdMobModelType, fetchTodayDateModel: FetchTodayDateModelType, commonDataModel: FetchCommonDataModelType, authenticationManager: AuthenticationManagerType, firestore: FirestoreWrapperProtocol) {
        todayDateModel = fetchTodayDateModel
        mapModel = model
        setAdMobModel = adMobModel
        CommonDataModel = commonDataModel
        AuthenticationManager = authenticationManager
        firestoreService = firestore
        // MARK: -AdMob設定
        //         VCのからバナーサイズが通知されるのでそれをModelに投げてAdmobバナー作成
        viewWidthSizeSubject
            .subscribe { [self] size in
                setAdMobModel.setAdMob(bannerWidthSize: size.element?.bannerWidth ?? 0, bannerHeight: size.element?.bannerHeight ?? 0, viewController: size.element!.VC)
            }
            .disposed(by: disposeBag)
        // AdMobバナー作成の結果をModelから受け取りVCに通知
        setAdMobModel
            .output
            .SetAdMobModelObservable
            .subscribe { [self] (setAdMob: AdBannerView) in
                SetAdMobModelRelay.accept(setAdMob as! GADBannerView)
            }
            .disposed(by: disposeBag)
        // MARK: -匿名ログインの確認が取れたらデータ取得メソッドを走らせる
        AuthenticationManager
            .output
            .authStatusObservable
            .filter { $0 == .anonymous }
            .subscribe(onNext: { [self] _ in
                // モデルから特定のデータを取得
                mapModel.input.fetchOtokuSpecialtyData()
                mapModel.input.fetchAddressDataFromRealTimeDB()
                todayRelay.accept(todayDateModel.input.fetchTodayDate())
            })
            .disposed(by: disposeBag)
        // MARK: -共有Modelよりインクリメントの有無をMapでも取得
        CommonDataModel
            .output
            .shouldUpdateDataObservable
            .subscribe { [self] judge in
                mapModel.input.shouldUpdateDataJudgeObserver.onNext(judge)
            }
            .disposed(by: disposeBag)
        // MARK: -slideShow
        //スライドショータップ時のURLをVCに通知
        slideShowCollectionViewSelectedIndexPathSubject
            .withLatestFrom(otokuSpecialtySubject) { indexPath, data in
                let selectedUrl = data[indexPath.row].webUrl
                return selectedUrl
            }
            .bind(to: slideShowCollectionViewSelectedUrlSubject)
            .disposed(by: disposeBag)
        //スライドショー表示用データをModelより取得
        mapModel
            .output
            .otokuSpecialtyObservable
            .subscribe { [self] data in
                otokuSpecialtySubject.onNext(data)
            }
            .disposed(by: disposeBag)
        // MARK: -ピン作成関係
        //住所データをModelより取得
        mapModel
            .output
            .AddressDataObservable
            .subscribe { [self] address in
                addressSubject.onNext(address)
            }
            .disposed(by: disposeBag)
        //共通メインデータをModelより取得
        CommonDataModel
            .output
            .fetchCommonDataModelObservable
            .subscribe {[self] data in
                articlesSubject.onNext(data)
            }
            .disposed(by: disposeBag)
        //緯度経度のないものを見つけてGeocoderのラインに流す
        addressSubject
            .map { mapModels in
                mapModels.filter { $0.longitude == nil || $0.latitude == nil }
                //⚠️ここに仕込む？違うサブジェクトにオブザーバブル側を変えるだけ
            }
            .compactMap(\.first)
            .subscribe(onNext: { [weak self] incompleteCoordinates in
                self?.processBox(incompleteCoordinates)
            })
            .disposed(by: disposeBag)
    }
    // MARK: - Geocoder
    // アドレス文字列ない、あるが空文字でない場合moveModelBoxFirstIfNeeded()　そうでない場合ジオコーディング実行
    func processBox(_ noLatitudeAndLongitude: OtokuAddressModel) {
        guard let content = noLatitudeAndLongitude.content, !content.isEmpty else {
            moveModelBoxFirstIfNeeded()
            return
        }
        //連続して流しすぎるとgeocodeAddressStringはエラーを返すので２秒待つ
        sleep(2)
        addressGeocoder.geocodeAddressString(content) { [weak self] placemarks, error in
            self?.handleGeocodingResult(placemarks, error: error, noLatitudeAndLongitude: noLatitudeAndLongitude)
        }
    }
    //現在書き込み不可。開発者のみ書き込める方が安全だから、このままで一時的に解除するか？保存先（firebaseを本番と開発で増設？）それはテストでやればいいか。
    //⭐️ここと　　これが完了したらリロードでOK？ーーではない。リロードしてもまた同じものが回ってくるから。（緯度経度が入ったら無視されるから）FB更新でも実質レルムのみの反応なので意味ない
    // ジオコーディングの結果を書き込み
    func handleGeocodingResult(_ placemarks: [CLPlacemark]?, error: Error?, noLatitudeAndLongitude data: OtokuAddressModel) {
        let ref = Database.database().reference()
        let path = "SecondOtokuAddressModelsObject"
        //        let path2 = "OtokuAddressModelsObjectForTest"
        guard error == nil, let coordinate = placemarks?.first?.location?.coordinate else {
            moveModelBoxFirstIfNeeded()
            return
        }
        let updateData = ["latitude": coordinate.latitude, "longitude": coordinate.longitude]
        ref.child("\(path)/\(data.address_id)").updateChildValues(updateData) { error, _ in//⚠️path2を新DBのpathに変える
            if let error = error {
                print("Error updating Firebase: \(error.localizedDescription)")
                self.moveModelBoxFirstIfNeeded()
            } else {
                // FBの更新が成功した場合の処理
                print("Firebase data updated successfully.")
                //⚠️レルムにキックバック（戻す）ちなみにオブザーバブルにした所でFireBaseと同じ
                self.updateRealmLocation(for: data.address_id, newLatitude: coordinate.latitude, newLongitude: coordinate.longitude)
                self.addressSubject.onNext(self.updateAddressSubject(forBoxId: data.address_id, withLatitude: coordinate.latitude, andLongitude: coordinate.longitude))
            }
        }
    }
    
    //ジオコーディング後レルムキックバックメソッド
    func updateRealmLocation(for addressId: String, newLatitude: Double, newLongitude: Double) {
        let realm = try! Realm()
        // 特定のaddress_idを持つオブジェクトを検索
        if let objectToUpdate = realm.object(ofType: OtokuAddressRealmModel.self, forPrimaryKey: addressId) {
            try! realm.write {
                // 新しい緯度と経度で更新
                objectToUpdate.latitude = newLatitude
                objectToUpdate.longitude = newLongitude
            }
        }
    }
    //失敗したものは順次削除
    private func moveModelBoxFirstIfNeeded() {
        if self.addAnnotationRetryCount < 50 {
            self.addAnnotationRetryCount += 1
            let currentValue = try? addressSubject.value()
            guard currentValue?.count ?? 1 >= 2, let removeId = currentValue?.first(where: {$0.longitude == nil})
                .map(\.address_id)
            else { return }
            let result: [OtokuAddressModel] = (currentValue?.filter {$0.address_id != removeId})!
            addressSubject.onNext(result)//removeした残り
        }
    }
    func updateAddressSubject(forBoxId boxId: String, withLatitude latitude: Double, andLongitude longitude: Double) -> [OtokuAddressModel] {
        guard let currentModels = try? addressSubject.value() else { return [] }
        let updatedModels = currentModels.map { model -> OtokuAddressModel in
            if model.address_id == boxId {
                // boxIdに一致するモデルの場合、新しい緯度と経度でモデルを更新
                return OtokuAddressModel(address_id: boxId, content: model.content, latitude: latitude, longitude: longitude)
            } else {
                // 一致しない場合は、モデルをそのまま返す
                return model
            }
        }
        return updatedModels
    }
    //    // MARK: -テスト関係
    //    func setupTestDataForTest(addAnnotationRetryCount: Int, selectSegmentIndexType: Int, todaysAnnotationModel: [OtokuMapModel]) {
    //        self.addAnnotationRetryCount = addAnnotationRetryCount
    //        // ⚠️       self.selectSegmentIndexType = selectSegmentIndexType
    //        self.todaysAnnotationModel.accept(todaysAnnotationModel)
    //    }
    //    func moveModelBoxFirstIfNeededForTest() {
    //        self.moveModelBoxFirstIfNeeded()
    //    }
    //    func getTodaysAnnotationModelForTest() -> [OtokuMapModel] {
    //        return self.todaysAnnotationModel.value
    //    }
    //    func setupTestDataForAllDaysAnnotationModelTest(addAnnotationRetryCount: Int, selectSegmentIndexType: Int, allDaysAnnotationModel: [OtokuMapModel]) {
    //        self.addAnnotationRetryCount = addAnnotationRetryCount
    //        self.allDaysAnnotationModel.accept(allDaysAnnotationModel)
    //    }
    //    func getAllDaysAnnotationModelForTest() -> [OtokuMapModel] {
    //        return self.allDaysAnnotationModel.value
    //    }
}
// MARK: - Input Implementation
extension MapViewModel: MapViewModelInput {
    var slideShowCollectionViewSelectedIndexPathObserver: AnyObserver<IndexPath> {
        return slideShowCollectionViewSelectedIndexPathSubject.asObserver()
    }
    var viewWidthSizeObserver: RxSwift.AnyObserver<SetAdMobModelData> {
        return viewWidthSizeSubject.asObserver()
    }
}
// MARK: - Output Implementation
extension MapViewModel: MapViewModelOutput {
    var slideShowCollectionViewSelectedUrlObservavable: Observable<String> {
        return slideShowCollectionViewSelectedUrlSubject.asObservable()//隠蔽のasObservable
    }
    var otokuSpecialtyObservable: Observable<[SlideShowModel]> {
        return otokuSpecialtySubject.asObservable()//隠蔽のasObservable
    }
    var SetAdMobModelObservable: Observable<GADBannerView> {
        return SetAdMobModelRelay.asObservable()//隠蔽とラッパー起因のasObservable
    }
    //当日ピンの分のデータ生成（VC監視）
    var mapTodaysModelObservable: Observable<[OtokuMapModel]> {
        Observable.combineLatest(
            addressSubject,// [OtokuAddressModel]　全てのアドレス
            todayInfosObservable// [OtokuDataModel]　絞り込んだ当日分データ
        )
        .map { address, info -> [OtokuMapModel] in// address[OtokuAddressModel], info[OtokuDataModel]
            info.flatMap { article -> [OtokuMapModel] in// article OtokuDataModel
                article.address_ids.compactMap {  id -> OtokuAddressModel? in// id String
                    address.first(where: { $0.address_id == id })// address[OtokuAddressModel].address_id---String == id---String
                }
                .convertOtokuMapModel(article: article)
            }
        }
    }
    //全てのピンの分のデータ生成（VC監視）
    var mapModelsObservable: Observable<[OtokuMapModel]> {
        Observable.combineLatest(
            addressSubject,//全てのアドレスデータ
            articlesSubject//全てのメインデータ
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
                    result.append(model)//ここでappend
                }
            }
            return result//ここ完了次第次
        }
    }
}
// MARK: - Additional Extensions
extension MapViewModel: MapViewModelType {
    var input: MapViewModelInput { return self }
    var output: MapViewModelOutput { return self }
}
// MARK: -　OtokuAddressModel + OtokuDataModel　→ OtokuMapModelへ変換
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
// MARK: -
extension CLGeocoder: AddressGeocoder {}
