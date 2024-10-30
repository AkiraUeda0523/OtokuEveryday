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
import Nuke

class CustomPointAnnotation: MKPointAnnotation {
    var url: String?
}
class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UIScrollViewDelegate {
    enum SegmentedType: Int {
        case today
        case all
    }
    @IBOutlet weak var allAnnotationMapView: MKMapView!
    @IBOutlet weak var segmentedControlButton: UISegmentedControl!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var slideShowCollectionView: UICollectionView!
    @IBOutlet weak var mapBannerView: UIView!
    @IBOutlet weak var currentLocationButton: UIButton!
    @IBOutlet weak var baseViewHeightConstraint: NSLayoutConstraint!
    private var admobBannerView: GADBannerView?
    
    // MARK: -プロパティ
    private var isScrubbing: Bool = false
    private var slideShowIndex = 0
    private var cellId = "SliderCell"
    private var slideShowTimer: Timer?
    private var selectSegmentIndexType: Int = 0
    private var slideShowArray = [SlideShowModel]()
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
        mapBannerView.backgroundColor = .clear
        HUD.show(.progress)
        slideShowCollectionView.dataSource = nil
        observeList()
        slideShowCollectionViewDidTap()
        // 今日のお得情報のピンをマップに追加する処理
        mapViewModel
            .output
            .mapTodaysModelObservable
            .observe(on: MainScheduler.instance)
            .subscribe { [weak self] boxs in
                // 各お得情報に対して処理を行う
                boxs.forEach { box in
                    // 緯度経度の情報がある場合のみ処理を進める
                    guard let latitude = box.address.latitude,
                          let longitude = box.address.longitude else { return }
                    // カスタムのピンを作成して設定
                    let pin = CustomPointAnnotation()
                    pin.subtitle = "ⓘ詳細を表示"
                    pin.url = box.blog_web_url
                    pin.title = box.article_title
                    pin.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
                    // マップにピンを追加
                    self?.mapView.addAnnotation(pin)
                }
                // ロード表示を非表示に
                HUD.hide()
            }
            .disposed(by: disposeBag)
        // 全てのお得情報のピンをマップに追加する処理
        mapViewModel
            .output
            .mapModelsObservable
            .observe(on: MainScheduler.instance)
            .subscribe { [weak self] boxs in
                // 各お得情報に対して処理を行う
                boxs.forEach { box in
                    // 緯度経度の情報がある場合のみ処理を進める
                    guard let latitude = box.address.latitude,
                          let longitude = box.address.longitude else { return }
                    // カスタムのピンを作成して設定
                    let pin = CustomPointAnnotation()
                    pin.subtitle = "ⓘ詳細を表示"
                    pin.url = box.blog_web_url
                    pin.title = box.article_title
                    pin.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
                    // オールマップビューにピンを追加
                    self?.allAnnotationMapView.addAnnotation(pin)
                }
                // ロード表示を非表示に
                HUD.hide()
            }
            .disposed(by: disposeBag)
        // スライドショーのデータを取得し、UIに表示する処理
        mapViewModel
            .output
            .otokuSpecialtyObservable
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] specialtyData in
                // スライドショー用の配列を初期化
                self?.slideShowArray = []
                // 新しいデータを配列に追加
                self?.slideShowArray.append(contentsOf: specialtyData)
                // ページコントロールのページ数を更新
                self?.pageControl.numberOfPages = self?.slideShowArray.count ?? 0
                // スライドショーのコレクションビューを更新
                self?.slideShowCollectionView.reloadData()
            })
            .disposed(by: disposeBag)
        // MARK: -
        // マップビューおよびロケーションマネージャーのデリゲートを設定し、UIの初期設定を行う
        mapView.delegate = self
        allAnnotationMapView.delegate = self
        locationManager.delegate = self
        self.view.backgroundColor = .systemRed // 背景色をシステムレッドに設定
        self.navigationController?.isNavigationBarHidden = true // ナビゲーションバーを非表示に設定
        // スライドショーの自動スクロールタイマーを開始
        startTimer()
        //ページコントロール、現在地ボタン、スライドショーのコレクションビュー、セグメントコントロールボタンのレイアウトを設定
        pageControlLayout() // ページコントロールのレイアウト設定
        currentLocationButtonLayout() // 現在地ボタンのレイアウト設定
        slideShowCollectionViewSetUp() // スライドショーのコレクションビューをセットアップ
        segmentedControlButtonLayout() // セグメントコントロールボタンのレイアウト設定
        // MARK: - 　現在地の利用許可
        // 位置情報サービスの認証ステータスが拒否されている場合にアラートを表示し、ユーザーに設定での変更を促す
        if self.locationManager.authorizationStatus == .denied {
            Alert.okAlert(vc: self, title: "アプリの位置情報サービスが\n許可されていません。", message: "設定に移動しますか？") { (_) in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
            }
        }
    }
    // MARK: - viewWillAppear
    // 画面が表示される直前に実行される処理
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // アプリがフォアグラウンドに戻った際の通知を受け取るためのオブザーバを設定
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        // 位置情報サービスの認証状況をViewModelに通知
        bindInput()
        // 位置情報サービスの認証が未決定の場合、ユーザーに認証を要求
        if self.locationManager.authorizationStatus == .notDetermined {
            self.locationManager.requestWhenInUseAuthorization()
        }
    }
    // MARK: - viewWillDisappear
    // 画面が非表示になる直前に実行される処理
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // バナーが不要になるので破棄
        removeAdMobBanner()
        // 通知の購読を終了し、オブザーバを削除
        notificationDisposable?.dispose()
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // バナーがまだ設定されていなければ設定する
        if admobBannerView == nil {
            setMapAdMobBanner()
        }
    }
    private func removeAdMobBanner() {
        // バナーが存在していれば削除
        admobBannerView?.removeFromSuperview()
        admobBannerView = nil
    }
    private func setMapAdMobBanner() {
        // バナーがすでに存在する場合は何もしない
        guard admobBannerView == nil else {
            return
        }
        // 広告バナーをViewModelから取得して設定する
        mapViewModel
            .output
            .SetAdMobModelObservable
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] setAdMob in
                guard let self = self else { return }
                // 広告バナーを表示する高さを設定
                let bannerHeight = setAdMob.adSize.size.height
                self.baseViewHeightConstraint.constant = bannerHeight
                // バナーを追加
                self.mapBannerView.addSubview(setAdMob)
                // 広告バナーの参照を保持して、次回使えるようにする
                self.admobBannerView = setAdMob
                // レイアウト制約を設定
                setAdMob.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    setAdMob.leadingAnchor.constraint(equalTo: self.mapBannerView.leadingAnchor),
                    setAdMob.trailingAnchor.constraint(equalTo: self.mapBannerView.trailingAnchor),
                    setAdMob.topAnchor.constraint(equalTo: self.mapBannerView.topAnchor),
                    setAdMob.heightAnchor.constraint(equalToConstant: bannerHeight)
                ])
                // レイアウトの更新をメインスレッドで実行
                self.view.layoutIfNeeded()
            })
            .disposed(by: disposeBag)
        // バナーサイズをViewModelに通知
        mapViewModel
            .input
            .viewWidthSizeObserver
            .onNext(SetAdMobModelData(bannerWidth: self.view.frame.width, bannerHeight: self.mapBannerView.frame.height, VC: self))
    }
    // MARK: - アプリの状態管理関連
    // アプリがフォアグラウンドに戻ったときの処理
    @objc private func willEnterForeground() {
        // 位置情報サービスがオフの場合、ユーザーにオンにするよう促すアラートを表示
        if !CLLocationManager.locationServicesEnabled() {
            let alert = UIAlertController(title: "位置情報サービスを\nオンにして下さい", message: "「設定」アプリ ⇒「プライバシー」⇒「位置情報サービス」からオンにできます", preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: { (_) in
                self.dismiss(animated: true, completion: nil)
            }))
            present(alert, animated: true, completion: nil)
        }
    }
    // アプリの状態変更に応じて必要な処理を実行するためのメソッド
    private func bindInput() {
        // NotificationCenterを使用して、アプリがアクティブになった際の通知を購読
        notificationDisposable = NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
            .subscribe(onNext: { [unowned self] _ in
                // 位置情報サービスの認証が未決定の場合、ユーザーに認証を要求
                if locationManager.authorizationStatus == .notDetermined {
                    locationManager.requestWhenInUseAuthorization()
                }
            })
    }
    // MARK: -
    // 現在地ボタンのレイアウト設定: 画像設定、アスペクト比、影の設定などを行う
    private func currentLocationButtonLayout() {
        currentLocationButton.apply {
            $0.setImage(currentLocationButtonsPicture, for: .normal) // ボタンの画像を設定
            $0.imageView?.contentMode = .scaleAspectFit // 画像のコンテンツモードを設定
            $0.contentHorizontalAlignment = .fill // 水平方向の配置を設定
            $0.contentVerticalAlignment = .fill // 垂直方向の配置を設定
            $0.layer.shadowOpacity = 0.3 // 影の不透明度を設定
            $0.layer.shadowRadius = 2 // 影の半径を設定
            $0.layer.shadowColor = UIColor.black.cgColor // 影の色を設定
            $0.layer.shadowOffset = CGSize(width: 3, height: 3) // 影のオフセットを設定
        }
    }
    // セグメントコントロールボタンのレイアウト設定: 影、テキストカラーの設定
    private func segmentedControlButtonLayout() {
        segmentedControlButton.apply {
            $0.layer.shadowOpacity = 0.3 // 影の不透明度を設定
            $0.layer.shadowRadius = 2 // 影の半径を設定
            $0.layer.shadowColor = UIColor.black.cgColor // 影の色を設定
            $0.layer.shadowOffset = CGSize(width: 3, height: 3) // 影のオフセットを設定
            $0.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected) // 選択時のテキストカラー
            $0.setTitleTextAttributes([.foregroundColor: UIColor.gray], for: .normal) // 通常時のテキストカラー
        }
    }
    // ページコントロールのレイアウト設定: 影の設定
    private func pageControlLayout() {
        pageControl.layer.apply {
            $0.shadowOpacity = 0.3 // 影の不透明度を設定
            $0.shadowRadius = 2 // 影の半径を設定
            $0.shadowColor = UIColor.black.cgColor // 影の色を設定
            $0.shadowOffset = CGSize(width: 3, height: 3) // 影のオフセットを設定
        }
    }
    // MARK: - CLLocationManagerのデリゲートメソッド
    // 位置情報サービスの認証状態が変更された際に呼ばれるメソッド
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        var region: MKCoordinateRegion
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            // 位置情報サービスの認証が許可されている場合、位置情報の更新を開始
            manager.startUpdatingLocation()
            let coordinate = mapView.userLocation.coordinate
            // 有効な座標が取得できれば、その座標を中心にマップを表示
            if CLLocationCoordinate2DIsValid(coordinate) {
                region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                mapView.region = region
                allAnnotationMapView.region = region
                mapView.userTrackingMode = .followWithHeading
                allAnnotationMapView.userTrackingMode = .followWithHeading
            }
        case .notDetermined, .denied:
            // 認証が未決定または拒否されている場合、デフォルトの座標を設定
            let defaultCoordinate = (mapView.userLocation.coordinate.latitude == 0 || mapView.userLocation.coordinate.latitude == -180) ?
            CLLocationCoordinate2DMake(34.7024, 135.4959) : mapView.userLocation.coordinate
            region = MKCoordinateRegion(center: defaultCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            mapView.region = region
            allAnnotationMapView.region = region
        case .restricted:
            // 制限されている場合の処理は特になし
            break
        @unknown default:
            // 未知の認証ステータスの場合の処理も特になし
            break
        }
    }
    // MARK: - CLLocationManagerのデリゲートメソッド
    /**
     ユーザーの位置情報が更新された際に呼び出されるメソッド。
     - Parameters:
     - manager: 位置情報を管理する`CLLocationManager`オブジェクト。
     - locations: 更新された位置情報の配列。最新の位置情報は配列の最初の要素です。
     */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let current = locations[0] // 最新の位置情報を取得
        // 現在地を中心とした地図の領域を設定
        let region = MKCoordinateRegion(center: current.coordinate, latitudinalMeters: 400, longitudinalMeters: 400)
        // mapViewとallAnnotationMapViewの両方に領域を設定
        mapView.setRegion(region, animated: true)
        allAnnotationMapView.setRegion(region, animated: true)
        // 両方のMapViewでユーザーの向きに追従するモードを設定
        allAnnotationMapView.userTrackingMode = .followWithHeading
        mapView.userTrackingMode = .followWithHeading
    }
    /**
     位置情報の取得に失敗した際に呼び出されるメソッド。
     - Parameters:
     - manager: 位置情報を管理する`CLLocationManager`オブジェクト。
     - error: 発生したエラー情報。
     */
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // デフォルトの地図領域を大阪駅周辺に設定
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let osakaStation = CLLocationCoordinate2DMake(34.7024, 135.4959)
        let region = MKCoordinateRegion(center: osakaStation, span: span)
        // 位置情報の取得に失敗した場合はデフォルト領域を表示
        mapView.region = region
        allAnnotationMapView.region = region
    }
    // MARK: - バルーン（吹き出し）関係
    /**
     地図上のアノテーションのビューを設定するメソッド。
     - Parameters:
     - mapView: アノテーションが表示される`MKMapView`インスタンス。
     - annotation: 表示するアノテーション。
     - Returns: アノテーションを表示するための`MKAnnotationView`インスタンス。
     */
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // ユーザーの現在位置のアノテーションは無視
        if annotation is MKUserLocation {
            return nil
        }
        // マーカーの外観をカスタマイズ
        let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
        annotationView.glyphText = "お得"
        annotationView.markerTintColor = .systemRed
        annotationView.glyphTintColor = .white
        annotationView.canShowCallout = true
        annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        return annotationView
    }
    /**
     地図上に新しいアノテーションを追加するメソッド。
     - Parameters:
     - title: アノテーションのタイトル。
     - id: アノテーションに関連付けるURLの文字列。
     - coordinate: アノテーションの座標。
     */
    func setAnnotation(title: String?, id: String?, coordinate: CLLocationCoordinate2D) {
        let annotation = CustomPointAnnotation()
        annotation.title = title
        annotation.url = id
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        allAnnotationMapView.addAnnotation(annotation)
    }
    /**
     アノテーションの吹き出しのアクセサリがタップされた時の処理を行うメソッド。
     - Parameters:
     - mapView: アノテーションが表示される`MKMapView`インスタンス。
     - view: タップされたアノテーションビュー。
     - control: タップされたコントロール。
     */
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let myAnnotation = view.annotation as? CustomPointAnnotation,
           let urlString = myAnnotation.url,
           let url = URL(string: urlString) {
            let safariView = SFSafariViewController(url: url)
            present(safariView, animated: true)
        }
    }
    /**
     アノテーションが選択された際の処理を行うメソッド。
     - Parameters:
     - mapView: アノテーションが表示される`MKMapView`インスタンス。
     - view: 選択されたアノテーションビュー。
     */
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // タップ時にサウンドエフェクトを再生
        AudioServicesPlaySystemSound(1519)
    }
    // MARK: - アクションハンドラー
    /**
     セグメントコントロールが選択された際のアクション。
     2つの異なるマップビュー（今日のマップとすべてのマップ）間の切り替えを行います。
     - Parameter sender: ユーザーが選択したセグメントコントロール。
     */
    @IBAction func segmentSelect(_ sender: UISegmentedControl) {
        AudioServicesPlaySystemSound(1519) // タップ音を再生
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        switch sender.selectedSegmentIndex {
        case 0:
            mapView.isHidden = false
            allAnnotationMapView.isHidden = true
            mapView.userTrackingMode = .followWithHeading
            let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, span: span)
            mapView.setRegion(region, animated: false)
        case 1:
            mapView.isHidden = true
            allAnnotationMapView.isHidden = false
            allAnnotationMapView.userTrackingMode = .followWithHeading
            let region = MKCoordinateRegion(center: allAnnotationMapView.userLocation.coordinate, span: span)
            allAnnotationMapView.setRegion(region, animated: false)
        default:
            break
        }
    }
    /**
     現在地ボタンがタップされた際のアクション。
     ユーザーの現在地にマップビューのフォーカスを移動します。
     - Parameter sender: 現在地ボタン。
     */
    @IBAction func currentLocationAction(_ sender: Any) {
        AudioServicesPlaySystemSound(1519) // タップ音を再生
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
    // MARK: - スライドショーコレクションビューのデータバインディング
    /**
     ViewModelから提供される「お得スペシャリティ」データをスライドショーコレクションビューにバインドします。
     各セルには画像、タイトル、コメントが表示されます。
     */
    private func observeList() {
        mapViewModel
            .output
            .otokuSpecialtyObservable
            .observe(on: MainScheduler.instance)
            .bind(to: slideShowCollectionView.rx.items(cellIdentifier: "SliderCell", cellType: SliderCell.self)) { row, element, cell in
                // 画像を設定
                if let url = URL(string: element.image) {
                    Nuke.loadImage(with: url, into: cell.slideImageView)
                }
                // コメントを設定
                cell.label.text = element.comment
                // タイトルを設定
                cell.titleLabel.text = element.title
            }
            .disposed(by: disposeBag)
    }
    // MARK: - スライドショーコレクションビューのタップ処理
    /**
     スライドショーコレクションビューの項目がタップされたときに実行される処理です。
     項目が選択解除され、システムサウンドが再生され、選択された項目のURLがSFSafariViewControllerで表示されます。
     */
    func slideShowCollectionViewDidTap() {
        slideShowCollectionView
            .rx
            .itemSelected
            .subscribe(onNext: { [unowned self] indexPath in
                self.slideShowCollectionView.deselectItem(at: indexPath, animated: true)
                // システムサウンドを再生
                AudioServicesPlaySystemSound(1519)
                // 選択された項目のURLをViewModelに通知
                mapViewModel.input.slideShowCollectionViewSelectedIndexPathObserver.onNext(indexPath)
            })
            .disposed(by: disposeBag)
        
        mapViewModel
            .output
            .slideShowCollectionViewSelectedUrlObservavable
            .subscribe { [self] url in
                // 選択されたURLをSFSafariViewControllerで表示
                guard let url = URL(string: url) else { return }
                let safariView = SFSafariViewController(url: url)
                present(safariView, animated: true)
            }
            .disposed(by: disposeBag)
    }
}
// MARK: - スライドショーに関するUICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayoutの拡張
extension MapViewController: UICollectionViewDelegateFlowLayout {
    // セルのサイズを指定
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: slideShowCollectionView.frame.width, height: slideShowCollectionView.frame.height - 20)
    }
    // スライドショーコレクションビューの設定を行うプライベートメソッド
    private func slideShowCollectionViewSetUp() {
        // カスタムセルを登録
        slideShowCollectionView.register(UINib(nibName: "SliderCell", bundle: nil), forCellWithReuseIdentifier: "SliderCell")
        slideShowCollectionView.showsHorizontalScrollIndicator = false
        // ページコントロールのイベントハンドラを設定
        pageControl.addTarget(self, action: #selector(pageControlValueChanged(sender:)), for: .valueChanged)
        pageControl.addTarget(self, action: #selector(pageControlDragEnded(sender:)), for: [.touchUpInside, .touchUpOutside])
        pageControl.addTarget(self, action: #selector(pageControlTouchDown(sender:)), for: .touchDown)
    }
    // タイマーを開始するプライベートメソッド
    private func startTimer() {
        if slideShowTimer == nil {
            slideShowTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        }
    }
    // タイマーを停止するプライベートメソッド
    private func stopTimer() {
        slideShowTimer?.invalidate()
        slideShowTimer = nil
    }
    // タイマーによる自動スライド処理
    @objc func timerAction() {
        let scrollPosition = (slideShowIndex < slideShowArray.count - 1) ? slideShowIndex + 1 : 0
        if scrollPosition < slideShowArray.count {
            slideShowCollectionView.scrollToItem(at: IndexPath(item: scrollPosition, section: 0), at: .centeredHorizontally, animated: true)
        }
    }
    // ページコントロールの値が変更されたときの処理
    @objc func pageControlValueChanged(sender: UIPageControl) {
        stopTimer() // タップ時にタイマーを停止
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.startTimer() // 3秒後に再開
        }
        let scrollPosition = sender.currentPage
        if scrollPosition < slideShowArray.count {
            slideShowCollectionView.scrollToItem(at: IndexPath(item: scrollPosition, section: 0), at: .centeredHorizontally, animated: !isScrubbing)
        }
    }
    // ページコントロールがタップされたときの処理
    @objc func pageControlTouchDown(sender: UIPageControl) {
        isScrubbing = true
        stopTimer() // スクラブ開始時にタイマーを停止
    }
    // ページコントロールのスクラブが終了したときの処理
    @objc func pageControlDragEnded(sender: UIPageControl) {
        isScrubbing = false
        startTimer() // スクラブ終了時にタイマーを再開
    }
    // スクロールビューがスクロールされたときの処理
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        slideShowIndex = Int(scrollView.contentOffset.x / slideShowCollectionView.frame.size.width)
        pageControl.currentPage = slideShowIndex
    }
}
