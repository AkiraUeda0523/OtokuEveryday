//
//  MapViewController.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2021/09/26

import UIKit
import MapKit
import RxSwift
import RxRelay
import AudioToolbox
import SafariServices
import GoogleMobileAds


class CustomPointAnnotation: MKPointAnnotation{
    var url: String?
}
class MapViewController: UIViewController,CLLocationManagerDelegate,MKMapViewDelegate,GetSpecialtyDataProtocol{//⭐️bindの件
    enum SegmentedType: Int{
        case today
        case all
    }
    @IBOutlet weak var segmentedControlButton: UISegmentedControl!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var slideShowCollectionView: UICollectionView!
    @IBOutlet weak var mapBannerView: GADBannerView!
    @IBOutlet weak var currentLocationButton: UIButton!
    // MARK: -プロパティ
    private var slideShowIndex = 0
    private var slideShowTimer : Timer?
    private var selectSegmentIndexType:Int = 0
    private var slideShowArray = [SlideShowModel]()
    private var adMobBannerView = GADBannerView()
    private var status = CLLocationManager.authorizationStatus()
    private let addressGeocoder = CLGeocoder()
    private let loadDBModel = LoadDBModel()
    private let adMobId = "xxxxxxxxxxxxxxxxxxxxxxxxxx"
    private let disposeBag = DisposeBag()
    private let currentLocationButtonsPicture = UIImage(named: "icon3")
    private let mapViewModel: MapViewModelType
    private var locationManager: CLLocationManager = {
        var locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = 100
        return locationManager
    }()
    // MARK: -init
    required init?(coder: NSCoder) {
        mapViewModel = MapViewModel(model: MapModel())
        super.init(coder: coder)
    }
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()

        mapViewModel
            .input
            .currentlyDisplayedVCRelay
            .debug()
            .subscribe { test in
                print(test)
            }
            .disposed(by: disposeBag)

        mapViewModel
            .output
            .modelBoxObservable
            .subscribe { [weak self]  boxs in
                boxs.forEach { box in//*
                    guard let latitude = box.address.latitude,
                          let longitude = box.address.longitude
                    else { return }
                    let pin = CustomPointAnnotation()
                    pin.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
                    pin.title = box.article_title
                    pin.subtitle = "ⓘ詳細を表示"
                    pin.url = box.blog_web_url
                    self!.mapView.addAnnotation(pin)
                }
            }
            .disposed(by: disposeBag)
        // MARK: -ステイト関係
        let foregroundJudge = Observable.of(mapViewModel.input.didEnterBackground, mapViewModel.input.willEnterForeground).merge().startWith(true)

        var isShow: Observable<Bool> {
            return Observable.combineLatest(foregroundJudge, mapViewModel.input.currentlyDisplayedVCRelay) {
                $0 == true && $1 == true
            }
        }
        // MARK: -ステイト関係
        Observable.combineLatest(isShow,mapViewModel.input.userLocationStatusRelay)
            .debug("debagtest")
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
        // MARK: -ステイト関係
        Observable.combineLatest(isShow,mapViewModel.input.userLocationStatusRelay)
            .filter{$0.0}
            .filter { $1.rawValue == 0 || $1.rawValue == 2}
            .subscribe (onNext: { test in
                if test.1.rawValue == 0{
                    self.locationManager.requestWhenInUseAuthorization()
                }
            })
            .disposed(by: disposeBag)
        // MARK: -ステイト関係
        mapViewModel.input.userLocationStatusRelay.onNext(status)
        // MARK: -
        mapView.delegate = self
        locationManager.delegate = self

        loadDBModel.fetchOtokuSpecialtyData()//*
        loadDBModel.getSpecialtyDataProtocol = self//*

        self.view.backgroundColor = .systemRed
        self.navigationController?.isNavigationBarHidden = true

        bindInput()
        startTimer()
        setUpAdmobView()
        pageControlLayout()
        currentLocationButtonLayout()
        slideShowCollectionViewSetUp()
        segmentedControlButtonLayout()
        // MARK: - 　現在地の利用許可
        locationManager.requestWhenInUseAuthorization()
        //進行方向を追跡
        mapView.userTrackingMode = MKUserTrackingMode.followWithHeading
    }// viewDidLoadはここまで
    // MARK: - viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // MARK: -ステイト関係
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    // MARK: - viewWillDisappear  非表示になる直前
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // MARK: -ステイト関係
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    // MARK: -ステイト関係
    @objc private func willEnterForeground() {
        if !CLLocationManager.locationServicesEnabled() {
            let alert = UIAlertController(title: "位置情報サービスを\nオンにして下さい", message: "「設定」アプリ ⇒「プライバシー」⇒「位置情報サービス」からオンにできます", preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: { (_) in
                self.dismiss(animated: true, completion: nil)
            }))
        }
    }

    private func bindInput() {
        NotificationCenter.default.rx.notification(UIApplication.willResignActiveNotification)
            .subscribe(onNext: { [unowned self] _ in
                // アプリがアクティブではなくなる時
                mapViewModel.input.foregroundJudgeRelay.onNext(false)
            })
            .disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
            .subscribe(onNext: { [unowned self] _ in
                // アプリがアクティブになった時
                mapViewModel.input.foregroundJudgeRelay.onNext(true)
            })
            .disposed(by: disposeBag)
    }
    // MARK: -
    func GetSpecialtyData(array: [SlideShowModel]) {//*
        self.slideShowArray = []
        self.slideShowArray = array
        pageControl.numberOfPages = slideShowArray.count
        slideShowCollectionView.reloadData()
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
    // MARK: -CLLocationManagerのデリゲートメソッド
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        mapViewModel.input.userLocationStatusRelay.onNext(status)
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

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let current = locations[0]
        let region = MKCoordinateRegion(center: current.coordinate,latitudinalMeters: 400, longitudinalMeters: 400);
        mapView.setRegion(region, animated: true)
        mapView.userTrackingMode = MKUserTrackingMode.followWithHeading
    }
    // requestLocation()が失敗した時に書いていないといけないメソッド
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let osakaStation = CLLocationCoordinate2DMake(34.7024, 135.4959)
        let region = MKCoordinateRegion(center: osakaStation, span: span)
        self.mapView.region = region
    }
    // MARK: -バルーン（吹き出し）関係
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
        let annotation = CustomPointAnnotation()//*
        annotation.title = title
        annotation.url = id
        annotation.coordinate = coodinate //*
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
    //本日or全てボタンTAP時Action
    @IBAction func segmentSelect(_ sender: UISegmentedControl) {//*
        AudioServicesPlaySystemSound(1519)
        self.mapView.removeAnnotations(self.mapView.annotations)

        self.selectSegmentIndexType = sender.selectedSegmentIndex
        let index = segmentedControlButton.selectedSegmentIndex
        if let type = SegmentedType(rawValue: index) {
            mapViewModel.input.currentSegmente.accept(type)
        }
    }
    //現在地に戻るボタンTAP時Action
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
    // MARK: - クラスここまで
}
// MARK: -　スライドショー　extension　 UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout

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
    //startTimer() #selector
    @objc func timerAction(){
        let ScrollPosition = (slideShowIndex < slideShowArray.count - 1) ? slideShowIndex + 1 : 0
        slideShowCollectionView.scrollToItem(at: IndexPath(item: ScrollPosition, section: 0), at: .centeredHorizontally, animated: true)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        slideShowIndex = Int(scrollView.contentOffset.x / slideShowCollectionView.frame.size.width)
        pageControl.currentPage = slideShowIndex
    }
}
