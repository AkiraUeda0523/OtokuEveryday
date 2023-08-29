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
import PKHUD

class CustomPointAnnotation: MKPointAnnotation{
    var url: String?
}
class MapViewController: UIViewController,CLLocationManagerDelegate,MKMapViewDelegate,UIScrollViewDelegate{
    enum SegmentedType: Int{
        case today
        case all
    }
    @IBOutlet weak var allAnnotationMapView: MKMapView!
    @IBOutlet weak var segmentedControlButton: UISegmentedControl!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var slideShowCollectionView: UICollectionView!
    @IBOutlet weak var mapBannerView: GADBannerView!
    @IBOutlet weak var currentLocationButton: UIButton!
    // MARK: -プロパティ
    private var slideShowIndex = 0
    private var cellId = "SliderCell"
    private var slideShowTimer : Timer?
    private var selectSegmentIndexType:Int = 0
    private var slideShowArray = [SlideShowModel]()
    private var adMobBannerView = GADBannerView()
    private var status = CLLocationManager.authorizationStatus()
    private let addressGeocoder = CLGeocoder()
    private let disposeBag = DisposeBag()
    private let currentLocationButtonsPicture = UIImage(named: "icon3")
    private let mapViewModel: MapViewModelType
    private var locationManager: CLLocationManager = {
        var locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = 100
        return locationManager
    }()
    var notificationDisposable: Disposable?
    
    // MARK: -init
    required init?(coder: NSCoder) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("AppDelegate is not accessible.")
        }
        mapViewModel = appDelegate.container.resolve(MapViewModel.self)!
        super.init(coder: coder)
    }
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        HUD.show(.progress)
        mapViewModel.input.fetchMapAllDataTriggerObserver.onNext(())
        slideShowCollectionView.dataSource = nil
        observeList()
        slideShowCollectionViewDidTap()
        
        mapViewModel
            .output
            .mapTodaysModelObservable
            .subscribe { [weak self]  boxs in
                boxs.forEach { box in
                    guard let latitude = box.address.latitude,
                          let longitude = box.address.longitude
                    else { return }
                    let pin = CustomPointAnnotation()
                    pin.subtitle = "ⓘ詳細を表示"
                    pin.url = box.blog_web_url
                    pin.title = box.article_title
                    pin.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
                    self?.mapView.addAnnotation(pin)
                }
                HUD.hide()
            }
            .disposed(by: disposeBag)
        
        mapViewModel
            .output
            .mapModelsObservable
            .subscribe { [weak self]  boxs in
                boxs.forEach { box in
                    guard let latitude = box.address.latitude,
                          let longitude = box.address.longitude
                    else { return }
                    let pin = CustomPointAnnotation()
                    pin.subtitle = "ⓘ詳細を表示"
                    pin.url = box.blog_web_url
                    pin.title = box.article_title
                    pin.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
                    self?.allAnnotationMapView.addAnnotation(pin)
                }
                HUD.hide()
            }
            .disposed(by: disposeBag)
        
        
        // MARK: -
        mapViewModel
            .output
            .otokuSpecialtyObservable
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] specialtyData in
                self?.slideShowArray = []
                self?.slideShowArray.append(contentsOf: specialtyData)
                self?.pageControl.numberOfPages = self?.slideShowArray.count ?? 0
                self?.slideShowCollectionView.reloadData()
                
            })
            .disposed(by: disposeBag)
        // MARK: -AdMob
        mapViewModel
            .output
            .SetAdMobModelObservable
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] setAdMob in
                self?.mapBannerView.addSubview(setAdMob)
            })
            .disposed(by: disposeBag)
        
        mapViewModel
            .input
            .viewWidthSizeObserver
            .onNext(SetAdMobModelData(size: self.view.frame.width, VC: self))
        // MARK: -
        mapView.delegate = self
        allAnnotationMapView.delegate = self
        locationManager.delegate = self
        self.view.backgroundColor = .systemRed
        self.navigationController?.isNavigationBarHidden = true
        //        bindInput()
        startTimer()
        pageControlLayout()
        currentLocationButtonLayout()
        slideShowCollectionViewSetUp()
        segmentedControlButtonLayout()
        // MARK: - 　現在地の利用許可
        if self.locationManager.authorizationStatus == .denied {
            Alert.okAlert(vc: self, title: "アプリの位置情報サービスが\n許可されていません。", message: "設定に移動しますか？"){ (_) in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)}
        }
    }
    // MARK: - viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // MARK: -ステイト関係
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        bindInput()
        
        mapViewModel.input.userLocationStatusRelay.onNext(status)
        
        
        let locationManager = CLLocationManager()
        if self.locationManager.authorizationStatus == .notDetermined {
            self.locationManager.requestWhenInUseAuthorization()
        }
    }
    // MARK: - viewWillDisappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // MARK: -ステイト関係
        notificationDisposable?.dispose()
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    // MARK: -ステイト関係
    @objc private func willEnterForeground() {
        if !CLLocationManager.locationServicesEnabled() {
            let alert = UIAlertController(title: "位置情報サービスを\nオンにして下さい", message: "「設定」アプリ ⇒「プライバシー」⇒「位置情報サービス」からオンにできます", preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: { (_) in
                self.dismiss(animated: true, completion: nil)
            }))
            present(alert, animated: true, completion: nil)
        }
    }
    private func bindInput() {
        notificationDisposable = NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
            .subscribe(onNext: { [unowned self] _ in
                if locationManager.authorizationStatus == .notDetermined {
                    locationManager.requestWhenInUseAuthorization()
                }
            })
    }
    // MARK: -
    private func currentLocationButtonLayout(){
        currentLocationButton.apply {
            $0.setImage(currentLocationButtonsPicture, for: .normal)
            $0.imageView?.contentMode = .scaleAspectFit
            $0.contentHorizontalAlignment = .fill
            $0.contentVerticalAlignment = .fill
            $0.layer.shadowOpacity = 0.3
            $0.layer.shadowRadius = 2
            $0.layer.shadowColor = UIColor.black.cgColor
            $0.layer.shadowOffset = CGSize(width: 3, height: 3)
        }
    }
    private func segmentedControlButtonLayout(){
        segmentedControlButton.apply{
            $0.layer.shadowOpacity = 0.3
            $0.layer.shadowRadius = 2
            $0.layer.shadowColor = UIColor.black.cgColor
            $0.layer.shadowOffset = CGSize(width: 3, height: 3)
            $0.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
            $0.setTitleTextAttributes([.foregroundColor: UIColor.gray], for: .normal)
        }
    }
    private func  pageControlLayout(){
        pageControl.layer.apply{
            $0.shadowOpacity = 0.3
            $0.shadowRadius = 2
            $0.shadowColor = UIColor.black.cgColor
            $0.shadowOffset = CGSize(width: 3, height: 3)
        }
    }
    // MARK: -CLLocationManagerのデリゲートメソッド
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("ststus変更",status.rawValue)
        print("どないなもんじゃい",locationManager.authorizationStatus)
        var region: MKCoordinateRegion
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
            let coordinate = mapView.userLocation.coordinate
            if CLLocationCoordinate2DIsValid(coordinate) {
                region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                mapView.region = region
                allAnnotationMapView.region = region
                mapView.userTrackingMode = .followWithHeading
                allAnnotationMapView.userTrackingMode = .followWithHeading
            }
        case .notDetermined, .denied:
            let defaultCoordinate = (mapView.userLocation.coordinate.latitude == 0 || mapView.userLocation.coordinate.latitude == -180) ?
            CLLocationCoordinate2DMake(34.7024, 135.4959) : mapView.userLocation.coordinate
            region = MKCoordinateRegion(center: defaultCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            mapView.region = region
            allAnnotationMapView.region = region
            
        case .restricted:
            break
        @unknown default:
            break
        }
    }
    //-------------------------------------------------------------------------------------------------
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let current = locations[0]
        let region = MKCoordinateRegion(center: current.coordinate,latitudinalMeters: 400, longitudinalMeters: 400);
        mapView.setRegion(region, animated: true)
        allAnnotationMapView.setRegion(region, animated: true)
        allAnnotationMapView.userTrackingMode = MKUserTrackingMode.followWithHeading
        
        mapView.userTrackingMode = MKUserTrackingMode.followWithHeading
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let osakaStation = CLLocationCoordinate2DMake(34.7024, 135.4959)
        let region = MKCoordinateRegion(center: osakaStation, span: span)
        self.mapView.region = region
        self.allAnnotationMapView.region = region
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
        let annotation = CustomPointAnnotation()
        annotation.title = title
        annotation.url = id
        annotation.coordinate = coodinate
        self.mapView.addAnnotation(annotation)
        self.allAnnotationMapView.addAnnotation(annotation)
        
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
        
        switch sender.selectedSegmentIndex {
        case 0:
            mapView.isHidden = false
            allAnnotationMapView.isHidden = true
        case 1:
            mapView.isHidden = true
            allAnnotationMapView.isHidden = false
        default:
            break
        }
    }
    @IBAction func currentLocationAction(_ sender: Any) {
        AudioServicesPlaySystemSound(1519)
        let defaultCoordinate = CLLocationCoordinate2D(latitude: 34.7024, longitude: 135.4959)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        var region = MKCoordinateRegion(center: mapView.userLocation.coordinate, span: span)
        switch locationManager.authorizationStatus {
        case .restricted, .denied, .notDetermined:
            if mapView.userLocation.coordinate.latitude == 0 || mapView.userLocation.coordinate.latitude == -180 {
                region = MKCoordinateRegion(center: defaultCoordinate, span: span)
            }
            if allAnnotationMapView.userLocation.coordinate.latitude == 0 || mapView.userLocation.coordinate.latitude == -180 {
                region = MKCoordinateRegion(center: defaultCoordinate, span: span)
            }
        case .authorizedAlways, .authorizedWhenInUse:
            mapView.userTrackingMode = .followWithHeading
            region = MKCoordinateRegion(center: mapView.userLocation.coordinate, span: span)
            allAnnotationMapView.userTrackingMode = .followWithHeading
            region = MKCoordinateRegion(center: allAnnotationMapView.userLocation.coordinate, span: span)
        @unknown default:
            break
        }
        mapView.region = region
        allAnnotationMapView.region = region
        
    }
    
    private func observeList() {
        mapViewModel
            .output
            .otokuSpecialtyObservable
            .observe(on: MainScheduler.instance)
            .bind(to: slideShowCollectionView.rx.items) { (collectionView, row, element) in
                let indexPath = IndexPath(row: row, section: 0)
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SliderCell", for: indexPath) as! SliderCell
                if let url = URL(string: element.image) {
                    cell.slideImageView.af.setImage(withURL: url)
                }
                cell.label.text = element.comment
                cell.titleLabel.text = element.title
                return cell
            }
            .disposed(by: disposeBag)
    }
    
    func slideShowCollectionViewDidTap() {
        slideShowCollectionView
            .rx
            .itemSelected
            .debug("反応あり")
            .subscribe(onNext: { [unowned self] indexPath in
                self.slideShowCollectionView.deselectItem(at: indexPath, animated: true)
                AudioServicesPlaySystemSound(1519)
                mapViewModel.input.slideShowCollectionViewSelectedIndexPathObserver.onNext(indexPath)
            })
            .disposed(by: disposeBag)
        
        mapViewModel
            .output
            .slideShowCollectionViewSelectedUrlObservavable
            .subscribe { [self] url in
                guard let url = URL(string: url) else {return}
                let safariView = SFSafariViewController(url: url)
                present(safariView, animated: true)
            }
            .disposed(by: disposeBag)
    }
}
// MARK: -　スライドショー　extension　 UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout

extension MapViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: slideShowCollectionView.frame.width, height: slideShowCollectionView.frame.height-20)
    }
    private func slideShowCollectionViewSetUp(){
        slideShowCollectionView.register(UINib(nibName: "SliderCell", bundle: nil), forCellWithReuseIdentifier: "SliderCell")
        slideShowCollectionView.showsHorizontalScrollIndicator = false
    }
    private func startTimer() {
        slideShowTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
    }
    @objc func timerAction(){
        let ScrollPosition = (slideShowIndex < slideShowArray.count - 1) ? slideShowIndex + 1 : 0
        if ScrollPosition < slideShowArray.count {
            slideShowCollectionView.scrollToItem(at: IndexPath(item: ScrollPosition, section: 0), at: .centeredHorizontally, animated: true)
        }
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        slideShowIndex = Int(scrollView.contentOffset.x / slideShowCollectionView.frame.size.width)
        pageControl.currentPage = slideShowIndex
    }
}
