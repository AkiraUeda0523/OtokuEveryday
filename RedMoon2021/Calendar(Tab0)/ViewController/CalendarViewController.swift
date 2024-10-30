//
//  CalendarViewController.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2021/09/10

import UIKit
import FSCalendar
import RxSwift
import RxCocoa
import PKHUD
import AudioToolbox
import CalculateCalendarLogic
import SafariServices
import Nuke
import GoogleMobileAds

final class CalendarViewController: UIViewController, FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance, UITabBarDelegate, UITabBarControllerDelegate {
    private let disposeBag = DisposeBag()
    private let cellId = "cellId"
    private let layout = UICollectionViewFlowLayout()
    internal var calendarViewModel: CalendarViewModelType
    private let defaultImageUrl = "https://harigamiya.jp/2x/in-preparetion-1@2x-100.jpg"
    @IBOutlet weak var otokuLogo: UIStackView!
    @IBOutlet weak var scrollBaseView: UIView!
    @IBOutlet var calendar: FSCalendar!
    @IBOutlet weak var otokuCollectionView: UICollectionView!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var bannerView: UIView!
    @IBOutlet weak var baseViewHeightConstraint: NSLayoutConstraint!
    private var admobBannerView: GADBannerView?
    // MARK: - リスナーを設定
    required init?(coder: NSCoder) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let calendarViewModel = appDelegate.container.resolve(CalendarViewModel.self) else {
            return nil
        }
        self.calendarViewModel = calendarViewModel
        super.init(coder: coder)
        checkVersion()//強制アップデート
        authStateCheck()//認証通ってから様々設定する為のメソッド
    }
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        bannerView.backgroundColor = .white
        setup()
        self.tabBarController?.delegate = self
        otokuLogo.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(titleLabelTapped))
        otokuLogo.addGestureRecognizer(tapGestureRecognizer)
    }
    // MARK: - viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
        setAutoScrollView()//⚠️⚠️何度も呼ばれる　　と言うことの意識しっかり！！！！
    }
    // MARK: - viewWillDisappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // バナーが不要になるので破棄
        removeAdMobBanner()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // バナーがまだ設定されていなければ設定する
        if admobBannerView == nil {
            setAdMobBanner()
        }
    }
    // MARK: - スクロールビューと広告バナーの設定
    /**
     自動スクロールビューの設定を行う関数。
     ViewModelから受け取ったスクロールビューを画面に追加します。
     */
    private func setAutoScrollView() {
        calendarViewModel
            .output
            .autoScrollModelObservable
            .observe(on: MainScheduler.instance) // ここでメインスレッドに切り替え
            .subscribe { event in
                switch event {
                case .next(let scrollView as UIView):
                    // スクロールビューをscrollBaseViewに追加
                    self.scrollBaseView.addSubview(scrollView)
                default:
                    break
                }
            }
            .disposed(by: disposeBag)
        // scrollBaseViewの大きさをViewModelに通知
        calendarViewModel.input.scrollBaseViewsBoundsObservable.onNext(self.scrollBaseView.bounds)
    }
    /**
     AdMobバナーの設定を行う関数。
     ViewModelから受け取った広告バナーを画面に追加します。
     */
    
    // MARK: - アドモブバナーを設定
    private func setAdMobBanner() {
        // バナーがすでに存在する場合は何もしない
        guard admobBannerView == nil else {
            return
        }
        calendarViewModel
            .output
            .setAdMobBannerObservable
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] setAdMob in
                guard let self = self else { return }
                // 新しくバナーを設定
                self.admobBannerView = setAdMob // バナーインスタンスを保持
                // 既存のビューからすべてのバナーを削除し、新しいバナーを追加
                self.bannerView.subviews.forEach { $0.removeFromSuperview() }
                // 高さを取得し、レイアウトを設定
                let bannerHeight = setAdMob.adSize.size.height
                self.baseViewHeightConstraint.constant = bannerHeight
                self.bannerView.addSubview(setAdMob)
                // レイアウト制約の設定
                setAdMob.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    setAdMob.leadingAnchor.constraint(equalTo: self.bannerView.leadingAnchor),
                    setAdMob.trailingAnchor.constraint(equalTo: self.bannerView.trailingAnchor),
                    setAdMob.topAnchor.constraint(equalTo: self.bannerView.topAnchor),
                    setAdMob.heightAnchor.constraint(equalToConstant: bannerHeight)
                ])
                
                self.view.layoutIfNeeded()
            })
            .disposed(by: disposeBag)
        
        // バナーサイズとVCを通知
        calendarViewModel
            .input
            .viewWidthSizeObserver
            .onNext(SetAdMobModelData(bannerWidth: view.frame.width, bannerHeight: bannerView.frame.height, VC: self))
    }
    // MARK: - アドモブバナーを削除
    private func removeAdMobBanner() {
        // バナーが存在すれば削除
        admobBannerView?.removeFromSuperview()
        admobBannerView = nil
    }
    // MARK: - コレクションビューの設定
    /**
     コレクションビューのデータソースを設定し、ViewModelからデータを受け取る関数。
     ViewModelから提供されるデータに基づき、コレクションビューの各セルを設定します。
     */
    private func collectionViewObserveList() {
        // コレクションビューのデリゲートとデータソースをリセット
        otokuCollectionView.delegate = nil
        otokuCollectionView.dataSource = nil
        // ViewModelから提供される情報を基にコレクションビューを更新
        calendarViewModel
            .output
            .showableInfosObservable
            .observe(on: MainScheduler.instance)
            .bind(to: otokuCollectionView.rx.items) { (collectionView: UICollectionView, row: Int, element: OtokuDataModel) -> UICollectionViewCell in
                let indexPath = IndexPath(row: row, section: 0)
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellId, for: indexPath) as? OtokuCollectionViewCell else {
                    fatalError("Cannot create new cell")
                }
                // セルに情報を設定
                cell.otokuLabel.text = element.article_title
                let url = URL(string: element.collectionView_image_url) ?? URL(string: self.defaultImageUrl)!
                cell.otokuImage.contentMode = url.absoluteString == self.defaultImageUrl ? .scaleAspectFit : .scaleAspectFill
                let options = ImageLoadingOptions(
                    transition: .fadeIn(duration: 0.5) // AlamofireImageのcrossDissolveに相当するフェードイン効果
                )
                // 画像の読み込みとセルのImageViewへのセット
                Nuke.loadImage(with: url, options: options, into: cell.otokuImage)
                return cell
            }
            .disposed(by: disposeBag)
    }
    /**
     コレクションビューのアイテム選択に関するイベントをハンドルする関数。
     ユーザーがアイテムをタップした際の処理を定義します。
     */
    private func collectionViewDidTap() {
        // コレクションビューのアイテム選択イベントを購読
        otokuCollectionView.rx.itemSelected
            .subscribe(onNext: { [unowned self] indexPath in
                // 選択されたアイテムの選択を解除
                self.otokuCollectionView.deselectItem(at: indexPath, animated: true)
                AudioServicesPlaySystemSound(1519) // 音を再生
                // ViewModelに選択されたインデックスパスを通知
                calendarViewModel.input.collectionViewSelectedIndexPathObserver.onNext(indexPath)
            })
            .disposed(by: disposeBag)
        // ViewModelからのURL通知を購読し、Safariビューを表示
        calendarViewModel
            .output
            .collectionViewSelectedUrlObservable
            .subscribe { [self] url in
                guard let url = URL(string: url) else {return}
                let safariView = SFSafariViewController(url: url)
                present(safariView, animated: true)
            }
            .disposed(by: disposeBag)
    }
    // MARK: - ローディングと表示状態の管理
    /**
     ViewModelからのデータロード状態を監視し、適切なUIアクションを実行する関数。
     コレクションビューの表示状態とローディングインジケーターの表示を制御します。
     */
    private func isLoadingAction() {
        // ViewModelからデータの表示可否を購読し、ビューの表示状態を更新
        calendarViewModel
            .output
            .showableInfosObservable
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] data in
                self?.otokuCollectionView.isHidden = data.isEmpty
                self?.emptyView.isHidden = !data.isEmpty
            })
            .disposed(by: disposeBag)
        // ViewModelからのローディング状態を購読し、HUDの表示を制御
        calendarViewModel
            .output
            .isLoadingObservable
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { isLoading in
                isLoading ? HUD.show(.progress) : HUD.hide()
            })
            .disposed(by: disposeBag)
    }
    /**
     タイトルラベルがタップされた際に実行される関数。
     現在の日付をカレンダーに選択し、ビューの初期化を行います。
     */
    @objc func titleLabelTapped() {
        AudioServicesPlaySystemSound(1519) // タップ音を再生
        let currentDate = Date()
        calendarViewModel.input.calendarSelectedDateObserver.onNext(currentDate)
        calendar.select(currentDate)
        otokuCollectionView.setContentOffset(.zero, animated: true)
        setup()
        setAutoScrollView()
    }
    /**
     タブバーコントローラーでの選択を制御する関数。
     特定のタブが選択されたときに特定の処理を行います。
     */
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if let navController = viewController as? UINavigationController,
           let topVC = navController.topViewController,
           topVC is CalendarViewController {
            titleLabelTapped() // カレンダービューのタイトルタップ処理を実行
            return true
        }
        return true // 他のタブの選択を許可
    }
    /**
     ビューコントローラーの初期設定を行う関数。
     さまざまなサブビューの設定を行い、データバインディングを初期化します。
     */
    func setup() {
        isLoadingAction() // ローディング状態の管理
        collectionViewDidTap() // コレクションビューのタップイベント設定
        // カレンダーとコレクションビューのデリゲートとデータソースを設定
        view.backgroundColor = .systemRed
        calendar.delegate = self
        calendar.dataSource = self
        otokuCollectionView.collectionViewLayout = layout
        otokuCollectionView.register(UINib(nibName: "OtokuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: cellId)
    }
    // MARK: - カレンダーレイアウトの設定
    /**
     コレクションビューのレイアウトを設定する関数。
     指定されたビューの幅に基づいてアイテムのサイズを計算します。
     */
    private func calendarCollectionViewLayout(view: UIView, layout: UICollectionViewFlowLayout) {
        let width = view.frame.width
        layout.itemSize = CGSize(width: (width - 20) / 3, height: (width - 20) / 3) // アイテムサイズを設定
    }
    /**
     FSCalendarの外観をカスタマイズする関数。
     カレンダーのヘッダーフォーマットや色設定を行います。
     */
    private func calendarsLayout(calendar: FSCalendar) {
        calendar.appearance.apply {
            $0.headerDateFormat = "YYYY年MM月"
            $0.titleWeekendColor = .red
            $0.todaySelectionColor = .systemRed
            $0.todayColor = .lightGray
            $0.headerTitleColor = .black
        }
        calendar.calendarWeekdayView.weekdayLabels.enumerated().forEach { index, label in
            switch index {
            case 0:
                label.text = "日"
                label.textColor = .systemRed
            case 6:
                label.text = "土"
                label.textColor = .systemIndigo
            default:
                label.text = ["月", "火", "水", "木", "金"][index - 1]
                label.textColor = .black
            }
        }
    }
    /**
     指定された日付が祝日かどうかを判断する関数。
     `CalculateCalendarLogic`ライブラリを使用して祝日かどうかを判定します。
     */
    func judgeHoliday(_ date: Date) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let holiday = CalculateCalendarLogic()
        return holiday.judgeJapaneseHoliday(year: year, month: month, day: day)
    }
    /**
     指定された日付が週の何日目かを返す関数。
     日曜日が1、土曜日が7となる週のインデックスを返します。
     */
    func getWeekIdx(_ date: Date) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.component(.weekday, from: date)
    }
    // MARK: - FSCalendarのデリゲートメソッド
    /**
     FSCalendarの日付選択時に呼び出されるデリゲートメソッド。
     選択された日付に基づいて特定のアクションを実行します。
     */
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        AudioServicesPlaySystemSound(1519) // サウンドエフェクトを再生
        calendarViewModel.input.calendarSelectedDateObserver.onNext(date) // 選択された日付をViewModelに通知
        otokuCollectionView.setContentOffset(CGPoint(x: 0, y: -otokuCollectionView.contentInset.top), animated: true) // コレクションビューを最上部にスクロール
    }
    /**
     FSCalendarの現在表示しているページが変更された時に呼び出されるデリゲートメソッド。
     カレンダーの再読み込みを行います。
     */
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        calendar.reloadData() // カレンダーのデータを再読み込み
    }
    /**
     FSCalendarで特定の日付のタイトルカラーを設定するデリゲートメソッド。
     祝日や週末に応じて色を変更します。
     */
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
        if calendar.scope == .month {
            // 現在表示中の月以外の日付は無視
            if Calendar.current.compare(date, to: calendar.currentPage, toGranularity: .month) != .orderedSame {
                return nil
            }
        }
        if judgeHoliday(date) {
            // 祝日は赤色で表示
            return UIColor.red
        }
        let weekday = getWeekIdx(date)
        if weekday == 1 {
            // 日曜日は赤色で表示
            return UIColor.red
        }
        else if weekday == 7 {
            // 土曜日は青色で表示
            return UIColor.systemBlue
        }
        return nil // 平日はデフォルトカラー
    }
}
// MARK: -extension init function
private extension CalendarViewController {
    // MARK: - 初期化関数の拡張
    /**
     アプリのバージョンチェックを行い、古い場合はアップデートを促す。
     AppStoreクラスを使用して現在のアプリバージョンとApp Storeのバージョンを比較します。
     */
    private func checkVersion() {
        AppStore.checkVersion { (isOlder: Bool) in
            guard isOlder else { return }
            let alertController = UIAlertController(title: "新しいバージョンがあります!", message: "アップデートお願い致します。", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "アップデート", style: .default) { action in
                AppStore.open() // App Storeを開いてアップデートを促す
            })
            alertController.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
            self.present(alertController, animated: true)
        }
    }
    /**
     ユーザーの認証状態をチェックし、適切なアクションを実行する。
     匿名ログインの状態やエラーが発生した場合に応じて処理を行います。
     */
    private func authStateCheck() {
        calendarViewModel
            .output
            .authStateObservable
            .observe(on: MainScheduler.instance)
            .withUnretained(self)  // selfを保持しつつ、selfが解放されていないかを確認
            .subscribe(onNext: { owner, auth in
                switch auth {
                case .anonymous:
                    PKHUD.sharedHUD.hide() // ローディングインジケータを非表示
                    owner.calendarCollectionViewLayout(view: owner.view, layout: owner.layout)
                    owner.calendarsLayout(calendar: owner.calendar)
                    owner.collectionViewObserveList()
                case .error(let message):
                    PKHUD.sharedHUD.hide() // ローディングインジケータを非表示
                    // エラーアラートを表示
                    let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .default))
                    owner.present(alertController, animated: true, completion: nil)
                case .retrying:
                    PKHUD.sharedHUD.show() // ローディングインジケータを表示
                }
            })
            .disposed(by: disposeBag)
    }
}
//⚠️初歩的な所
//値型参照型
//循環参照とself
//
//⚠️

//やるべき
//GitHubアクションズCI
//レコメンドリファクタ
//Swiftコンカレンシー
