//
//  MapViewController.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2021/09/26
import Foundation
import UIKit
import MapKit
import Firebase
import FirebaseFirestore
import PKHUD
import AudioToolbox
import GoogleMobileAds
import RxSwift
import RxRelay
import SafariServices


class CustomPointAnnotation : MKPointAnnotation {
    var url: String?
}


class MapViewController :UIViewController,CLLocationManagerDelegate,MKMapViewDelegate,GetSpecialtyDataProtocol{

    private enum SegmentedType: Int {
        case today
        case all
    }

    @IBOutlet weak var segmentedControlButton: UISegmentedControl!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var slideShowCollectionView: UICollectionView!
    @IBOutlet weak var mapBannerView: GADBannerView!
    @IBOutlet weak var currentLocationButton: UIButton!

    private var slideShowIndex = 0
    private var slideShowTimer : Timer?
    private var db = Firestore.firestore()
    private var selectSegmentIndexType:Int = 0
    private var addAnnotationRetryCount = 0
    private var slideShowArray = [SlideShowModel]()
    private var dataConstructionModel = DataConstructionModel()
    private var adMobBannerView = GADBannerView()
    private var status = CLLocationManager.authorizationStatus()

    let mapStateManagementModel = MapStateManagementModel.shared
    private let addressGeocoder = CLGeocoder()
    private let loadDBModel = LoadDBModel()
    private let adMobId = "xxxxxxxxxxxxxxxxxxxxxxxxx"
    private let disposeBag = DisposeBag()
    private let currentLocationButtonsPicture = UIImage(named: "icon3")
    private let dBRegisterModel = DBRegisterModel()
    private let mapModel = MapModel()
    // MARK: -
    private var locationManager: CLLocationManager = {
        var locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = 100
        return locationManager
    }()
    // MARK: -Rx Observable
    private let allDaysAnnotationModel = BehaviorRelay<[OtokuMapModel]>(value: [])
    private let todaysAnnotationModel = BehaviorRelay<[OtokuMapModel]>(value: [])
    private let currentSegmente = BehaviorRelay<SegmentedType>(value: .today)
    let testmodelBoxObservable = BehaviorRelay<[OtokuMapModel]>(value: [])
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()

        let foregroundJudge = Observable.of(mapStateManagementModel.didEnterBackground, mapStateManagementModel.willEnterForeground).merge().startWith(true)

        var isShow: Observable<Bool> {
            return Observable.combineLatest(foregroundJudge, mapStateManagementModel.currentlyDisplayedVCRelay) {
                $0 == true && $1 == true
            }
        }
        // MARK: -
        Observable.combineLatest(isShow,mapStateManagementModel.LocationStatus)
            .filter{$0.0}
            .filter { $1.rawValue == 0 || $1.rawValue == 2}
            .take(1)
            .subscribe (onNext: { test in
                if test.1.rawValue == 2{
                    Alert.okAlert(vc: self, title: "アプリの位置情報サービスが\n許可されていません。", message: "設定に移動しますか？") { (_) in
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)}
                }
            })
            .disposed(by: disposeBag)
        // MARK: -
        Observable.combineLatest(isShow,mapStateManagementModel.LocationStatus)
            .filter{$0.0}
            .filter { $1.rawValue == 0 || $1.rawValue == 2}
            .subscribe (onNext: { test in
                if test.1.rawValue == 0{
                    self.locationManager.requestWhenInUseAuthorization()
                }
            })
            .disposed(by: disposeBag)
        // MARK: -
        mapStateManagementModel.userLocationStatusRelay.accept(status)
        //自動保存メソッド⚠️
        //       dBRegisterModel.registarContent()
        //       dBRegisterModel.registarDocumentID()
        locationManager.delegate = self
        mapView.delegate = self
        loadDBModel.getSpecialtyDataProtocol = self
        loadDBModel.fetchOtokuSpecialtyData()
        self.navigationController?.isNavigationBarHidden = true
        self.view.backgroundColor = .systemRed

        slideShowCollectionViewSetUp()
        setUpAdmobView()
        currentLocationButtonLayout()
        segmentedControlButtonLayout()
        pageControlLayout()
        bindInput()
        // MARK: - 　現在地の利用許可
        locationManager.requestWhenInUseAuthorization()
        mapView.userTrackingMode = MKUserTrackingMode.followWithHeading

        if let tabBarController = self.tabBarController{
            tabBarController.rx
                .selectedIndex
                .subscribe({ print("デバッグ①",$0) })
                .disposed(by: disposeBag)
        }
        // MARK: -
        let modelBoxObservable = currentSegmente
            .withUnretained(self)
            .flatMap { weakSelf, type -> Observable<[OtokuMapModel]> in
                switch type {

                case .today:
                    self.addAnnotationRetryCount = 0
                    self.mapView.removeAnnotations(self.mapView.annotations)
                    return weakSelf.todaysAnnotationModel.asObservable()

                case .all:
                    self.addAnnotationRetryCount = 0
                    self.mapView.removeAnnotations(self.mapView.annotations)
                    return weakSelf.allDaysAnnotationModel.asObservable()
                }
            }
            .share(replay: 1)//Hot変換
        // MARK: -
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
        // MARK: -
        modelBoxObservable
        //            .debug("でばっぐでばっぐ")
            .map { boxs in//型推論省略
                boxs.filter { $0.address.longitude != nil && $0.address.latitude != nil }
            }
            .filter{models in
                let adresses = models.map(\.address.longitude)
                return !adresses.contains(where: {$0 == nil})
            }
        //            .distinctUntilChanged()//状態変化無しを無視
            .subscribe(onNext: { [self] boxs in
                boxs.forEach { box in
                    guard let latitude = box.address.latitude,
                          let longitude = box.address.longitude
                    else { return }
                    let pin = CustomPointAnnotation()
                    pin.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
                    pin.title = box.article_title
                    pin.subtitle = "ⓘ詳細を表示"
                    pin.url = box.blog_web_url
                    self.mapView.addAnnotation(pin)
                    //                    self.moveTodaysModelBoxFirstIfNeeded()
                }
            })
            .disposed(by: disposeBag)
        // MARK: -
        dataConstructionModel
            .mapTodaysModel
            .subscribe(onNext: { [weak self] todayArticle in
                self?.todaysAnnotationModel.accept(todayArticle)
            })
            .disposed(by: disposeBag)
        // MARK: -
        dataConstructionModel
            .mapModels
            .subscribe(onNext: { [weak self] allArticle in
                self?.allDaysAnnotationModel.accept(allArticle)
            })
            .disposed(by: disposeBag)
        // MARK: -
        mapModel.fetchAllOtokuDataFromRealTimeDB(dataConstructionModel: dataConstructionModel)//全てのデータ⚠️⚠️新
        mapModel.fetchAddressDataFromRealTimeDB(dataConstructionModel: dataConstructionModel)//全てのアドレス
        //      viewControllerModel.fetchAddressData()//全てのデータ⚠️旧
        //      viewControllerModel.fetchAllOtokuData()//全てのアドレス
        let today = GetDateModel.gatToday()
        dataConstructionModel.selectDate(today)
        startTimer()
    }// viewDidLoadはここまである





    // MARK: -   Rxはここまで　　　　　　　リファ　→→ region以外　　VMへ  リファ　→→ regionを残すイメージ（それ以外をVMに持たせる）
    // MARK: - viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    // MARK: - viewDidAppear　　全て描画が終わった後
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }
    // MARK: - viewWillDisappear  画面が非表示になる直前
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)

    }
    // MARK: -
    @objc private func willEnterForeground() {
        if !CLLocationManager.locationServicesEnabled() {
            let alert = UIAlertController(title: "位置情報サービスを\nオンにして下さい", message: "「設定」アプリ ⇒「プライバシー」⇒「位置情報サービス」からオンにできます", preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: { (_) in
                self.dismiss(animated: true, completion: nil)
            }))
        }
    }
    // MARK: -
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
    // MARK: -
    private func currentLocationButtonLayout(){
        currentLocationButton.setImage(currentLocationButtonsPicture, for: .normal)
        currentLocationButton.imageView?.contentMode = .scaleAspectFit
        currentLocationButton.contentHorizontalAlignment = .fill
        currentLocationButton.contentVerticalAlignment = .fill
        currentLocationButton.layer.shadowOpacity = 0.3
        currentLocationButton.layer.shadowRadius = 2
        currentLocationButton.layer.shadowColor = UIColor.black.cgColor
        currentLocationButton.layer.shadowOffset = CGSize(width: 3, height: 3)
    }
    private func segmentedControlButtonLayout(){
        segmentedControlButton.layer.shadowOpacity = 0.3
        segmentedControlButton.layer.shadowRadius = 2
        segmentedControlButton.layer.shadowColor = UIColor.black.cgColor
        segmentedControlButton.layer.shadowOffset = CGSize(width: 3, height: 3)
        segmentedControlButton.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segmentedControlButton.setTitleTextAttributes([.foregroundColor: UIColor.gray], for: .normal)
    }
    private func  pageControlLayout(){
        pageControl.layer.shadowOpacity = 0.3
        pageControl.layer.shadowRadius = 2
        pageControl.layer.shadowColor = UIColor.black.cgColor
        pageControl.layer.shadowOffset = CGSize(width: 3, height: 3)
    }
    private func setUpAdmobView(){
        adMobBannerView = GADBannerView(adSize:GADAdSizeBanner)
        adMobBannerView.frame.size = CGSize(width:self.view.frame.width, height:adMobBannerView.frame.height)
        adMobBannerView.adUnitID = adMobId
        adMobBannerView.rootViewController = self
        mapBannerView.addSubview(adMobBannerView)
        adMobBannerView.load(GADRequest())
    }
    // MARK: - 　　CLLocationManagerのデリゲートメソッド

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        mapStateManagementModel.userLocationStatusRelay.accept(status)
            switch status {

            case .authorizedAlways, .authorizedWhenInUse:
                manager.startUpdatingLocation()
                let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, span: span)
                mapView.region = region
                mapView.userTrackingMode = MKUserTrackingMode.followWithHeading

            case .notDetermined:
                if mapView.userLocation.coordinate.latitude == -180{
                    let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    let osakaStation = CLLocationCoordinate2DMake(34.7024, 135.4959)
                    let region = MKCoordinateRegion(center: osakaStation, span: span)
                    self.mapView.region = region
                }else{
                    let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, span: span)
                    mapView.region = region
                    mapView.userTrackingMode = MKUserTrackingMode.followWithHeading
                    }

            case .denied:
                if mapView.userLocation.coordinate.latitude == -180{
                    let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    let osakaStation = CLLocationCoordinate2DMake(34.7024, 135.4959)
                    let region = MKCoordinateRegion(center: osakaStation, span: span)
                    self.mapView.region = region
                }else{
                    let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, span: span)
                    mapView.region = region
                    mapView.userTrackingMode = MKUserTrackingMode.followWithHeading
                    }
                break
            case .restricted:
                break
            default:
                break
            }
    }
    // MARK: - 　　CLLocationManagerのデリゲートメソッド
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let current = locations[0]
        let region = MKCoordinateRegion(center: current.coordinate,latitudinalMeters: 400, longitudinalMeters: 400);
        mapView.setRegion(region, animated: true)
        mapView.userTrackingMode = MKUserTrackingMode.followWithHeading
    }
    // MARK: - 　　CLLocationManagerのデリゲートメソッド　　　 　　　requestLocation()が失敗した時に書いていないといけないメソッド
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let osakaStation = CLLocationCoordinate2DMake(34.7024, 135.4959)
        let region = MKCoordinateRegion(center: osakaStation, span: span)
        self.mapView.region = region
    }
    // MARK: - バルーン（吹き出し）関係
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?{
        if (annotation is MKUserLocation) {
            return nil
        }
        let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
        annotationView.glyphText = "お得"
        annotationView.markerTintColor = .systemRed
        annotationView.glyphTintColor = .white
        annotationView.canShowCallout = true
        annotationView.rightCalloutAccessoryView = UIButton(type: UIButton.ButtonType.detailDisclosure)
        return annotationView
    }

    func setAnnotation(title:String?,id:String?,coodinate:CLLocationCoordinate2D){
        let annotation = CustomPointAnnotation() // リファ
        annotation.title = title
        annotation.url = id
        annotation.coordinate = coodinate // リファ
        self.mapView.addAnnotation(annotation)
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let myAnnotation:CustomPointAnnotation = view.annotation as? CustomPointAnnotation {
            let url = URL(string: myAnnotation.url!)
            let safariView = SFSafariViewController(url: url!)
                 present(safariView, animated: true)
                  }
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        AudioServicesPlaySystemSound(1519)
    }
    // MARK: - @IBAction
    @IBAction func segmentSelect(_ sender: UISegmentedControl) {
        AudioServicesPlaySystemSound(1519)
        self.selectSegmentIndexType = sender.selectedSegmentIndex
        let index = segmentedControlButton.selectedSegmentIndex
        if let type = SegmentedType(rawValue: index) {
            currentSegmente.accept(type)
        }
    }

    @IBAction func currentLocationAction(_ sender: Any) {
        AudioServicesPlaySystemSound(1519)
        switch status {
        case .restricted,.denied:

            if mapView.userLocation.coordinate.latitude == -180{
                let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                let osakaStation = CLLocationCoordinate2DMake(34.7024, 135.4959)
                let region = MKCoordinateRegion(center: osakaStation, span: span)
                self.mapView.region = region
            }else{
                let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, span: span)
                mapView.region = region
                mapView.userTrackingMode = MKUserTrackingMode.followWithHeading}
        case .notDetermined:

            if mapView.userLocation.coordinate.latitude == -180{
                let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                let osakaStation = CLLocationCoordinate2DMake(34.7024, 135.4959)
                let region = MKCoordinateRegion(center: osakaStation, span: span)
                self.mapView.region = region
            }else{
                let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, span: span)
                mapView.region = region
                mapView.userTrackingMode = MKUserTrackingMode.followWithHeading}
        case .authorizedAlways:

               let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
               let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, span: span)
               mapView.region = region
               mapView.userTrackingMode = MKUserTrackingMode.followWithHeading
        case .authorizedWhenInUse:

               let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
               let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, span: span)
               mapView.region = region
               mapView.userTrackingMode = MKUserTrackingMode.followWithHeading

        @unknown default:
               let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
               let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, span: span)
               mapView.region = region
               mapView.userTrackingMode = MKUserTrackingMode.followWithHeading
        }
    }

    private func bindInput() {

        NotificationCenter.default.rx.notification(UIApplication.willResignActiveNotification)
            .subscribe(onNext: { [unowned self] _ in
                // アプリがアクティブではなくなる時
                self.mapStateManagementModel.foregroundJudgeRelay.accept(false)
            })
            .disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
            .subscribe(onNext: { [unowned self] _ in
                // アプリがアクティブになった時
                self.mapStateManagementModel.foregroundJudgeRelay.accept(true)
            })
            .disposed(by: disposeBag)
    }
        // MARK: - クラスのラスト
}
// MARK: -　スライドショー　　　extension　slideCollectionView： UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,TabBarDelegate

extension MapViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return slideShowArray.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = slideShowCollectionView.dequeueReusableCell(withReuseIdentifier: "SliderCell", for: indexPath) as! SliderCell
        cell.SlideImageView.sd_setImage(with: URL(string: slideShowArray[indexPath.row].image))
        cell.label.text = slideShowArray[indexPath.row].comment
        cell.titleLabel.text = slideShowArray[indexPath.row].title
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: slideShowCollectionView.frame.width, height: slideShowCollectionView.frame.height-20)
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        AudioServicesPlaySystemSound(1519)
        let url = URL(string: self.slideShowArray[indexPath.row].webUrl)
        let safariView = SFSafariViewController(url: url!)
             present(safariView, animated: true)
    }
    private func slideShowCollectionViewSetUp(){
        slideShowCollectionView.delegate = self
        slideShowCollectionView.dataSource = self
        slideShowCollectionView.register(UINib(nibName: "SliderCell", bundle: nil), forCellWithReuseIdentifier: "SliderCell")
        slideShowCollectionView.showsHorizontalScrollIndicator = false
    }
    private func startTimer() {
        slideShowTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
    }
    @objc func timerAction(){
        let ScrollPosition = (slideShowIndex < slideShowArray.count - 1) ? slideShowIndex + 1 : 0
        slideShowCollectionView.scrollToItem(at: IndexPath(item: ScrollPosition, section: 0), at: .centeredHorizontally, animated: true)
    }
    func GetSpecialtyData(array: [SlideShowModel]) {
        self.slideShowArray = []
        self.slideShowArray = array
        pageControl.numberOfPages = slideShowArray.count
        slideShowCollectionView.reloadData()
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        slideShowIndex = Int(scrollView.contentOffset.x / slideShowCollectionView.frame.size.width)
        pageControl.currentPage = slideShowIndex
    }
}
// MARK: -
extension Reactive where Base: UITabBarController {
    public var selectedIndex: Observable<Int> {
        return self.observeWeakly(UIViewController.self, "selectedViewController")
            .compactMap{$0}
            .compactMap { [weak base] in
                base?.viewControllers?.index(of: $0)
            }
    }
}


