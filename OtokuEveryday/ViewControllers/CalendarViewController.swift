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
import Firebase
import FirebaseFirestore
import ViewAnimator
import AudioToolbox
import CalculateCalendarLogic
import GoogleMobileAds//サポート
import FirebaseDatabase
import SafariServices
import AlamofireImage

final class CalendarViewController: UIViewController, FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance, UITabBarDelegate {
    private let disposeBag = DisposeBag()
    private let cellId = "cellId"
    private let scrollLabel = AutoScrollLabel()
    private let layout = UICollectionViewFlowLayout()
    private let AdMobID = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    private let calendarViewModel: CalendarViewModelType
    private var authHandle: AuthStateDidChangeListenerHandle!
    private var retryCount = 0
    private var rxOtokuArray = [OtokuDataModel]()
    private var calenderModel = CalendarModel()

    deinit{
        Auth.auth().removeStateDidChangeListener(authHandle)
    }
    @IBOutlet weak var scrollBaseView: UIView!
    @IBOutlet var calendar: FSCalendar!
    @IBOutlet weak var otokuCollectionView: UICollectionView!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var bannerView: UIView!
    // MARK: - リスナーを設定
    required init?(coder: NSCoder) {
        calendarViewModel = CalendarViewModel(model: calenderModel)
        super.init(coder: coder)
        checkVersion()
        authStateCheck()//check
    }
    // MARK: - viewDidLayoutSubviews（横にcell３つまで）
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        CalenderColectionViewLayout.calendarCollectionViewLayout(view: self.view, layout: layout)//Static　question
    }
    // MARK: - viewWillLayoutSubviews
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        CalendarsLayout.calendarsLayout(calendar: calendar)//Static
    }
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        // MARK: - Rx
        calendarViewModel
            .output
            .showableInfosObservable
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: {  [weak self] data in
                guard let strongSelf = self else { return }
                strongSelf.otokuCollectionView.isHidden = data.count == .zero//ロジック？
                strongSelf.emptyView.isHidden = data.count > .zero
                strongSelf.rxOtokuArray = data
                strongSelf.otokuCollectionView.reloadData()
            })
            .disposed(by: disposeBag)

        calendarViewModel
            .output
            .scrollTitleObservable
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self]   data in
                guard let strongSelf = self else { return }
                strongSelf.scrollLabel.textColor = .black
                strongSelf.scrollLabel.backgroundColor = .white
                var scrollWord = "日付をタップすると情報が切り替わります。　　　　　　　　　         　 　　　　　　【本日のお得情報】"//ロジック？
                for i in 0 ..< data.count {
                    scrollWord += "\(data[i].title)　　　"
                }
                strongSelf.scrollLabel.text = scrollWord
            })
            .disposed(by: disposeBag)

        calendarViewModel
            .output
            .isLoadingObservable
            .subscribe(onNext: { isLoading in
                isLoading ? HUD.show(.progress) : HUD.hide()
            })
            .disposed(by: disposeBag)
        // MARK: -AdMob
        SetAdMobModel.setAdMob(bannerView: self.bannerView, view: self.view, Self: self)//Static
        // MARK: -
        self.view.backgroundColor = .systemRed
        self.calendar.delegate = self//selfをクラス変更
        self.calendar.dataSource = self
        otokuCollectionView.delegate = self
        otokuCollectionView.dataSource = self
        otokuCollectionView.collectionViewLayout = layout
        otokuCollectionView.register(UINib(nibName: "OtokuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: cellId)
    }// viewDidLoadここまで

    // MARK: - viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
        scrollBaseView.addSubview(scrollLabel)
    }
    // MARK: -
    func authStateCheck(){
        calendarViewModel
            .output
            .authObservable
            .subscribe (onNext: { [weak self] auth in
                self?.authHandle = auth
                print("check",auth)
            })
            .disposed(by: disposeBag)
    }
    // MARK: - カレンダーデリゲートメソッド
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        AudioServicesPlaySystemSound(1519)//question
        calendarViewModel.input.selectDateObserver.onNext(date)
    }
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        calendar.reloadData()
    }
    // 土日や祝日の日の文字色を変える
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
        if calendar.scope == .month {//question  Model?
            //  現在表示されているページの月とセルの月が異なる場合には nil を戻す
            if Calendar.current.compare(date, to: calendar.currentPage, toGranularity: .month) != .orderedSame {
                return nil
            }
        }
        //祝日判定をする（祝日は赤色で表示する）
        if CalendarsLayout.judgeHoliday(date){
            return UIColor.red
        }
        //土日の判定を行う（土曜日は青色、日曜日は赤色で表示する）
        let weekday = CalendarsLayout.getWeekIdx(date)
        if weekday == 1 {   //日曜日
            return UIColor.red
        }
        else if weekday == 7 {  //土曜日
            return UIColor.systemBlue
        }
        return nil
    }
}

// MARK: -UICollectionViewDelegate, UICollectionViewDataSource

extension CalendarViewController:UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return rxOtokuArray.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {//question
        let cell = otokuCollectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! OtokuCollectionViewCell
        CalenderColectionViewLayout.CalenderColectionViewLayout(cell: cell, rxOtokuArray: rxOtokuArray, indexPath: indexPath)
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {//入力と出力？　indexPath
        AudioServicesPlaySystemSound(1519)
        let selectedWebPage = rxOtokuArray[indexPath.row].blog_web_url
        guard let url = URL(string: selectedWebPage) else {return}
        let safariView = SFSafariViewController(url: url)
        present(safariView, animated: true)
    }
    func didSelectTab(tabBarController: BaseTabBarController) {
        AudioServicesPlaySystemSound(1519)
    }
}
private extension CalendarViewController {//切り分け
    func checkVersion() {
        AppStore.checkVersion { (isOlder: Bool) in
            guard isOlder else { return }
            let alertController = UIAlertController(title: "新しいバージョンがあります!", message: "アップデートお願い致します。", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "アップデート", style: .default) { action in
                AppStore.open()
            })
            alertController.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
            self.present(alertController, animated: true)
        }
    }
}








////
////  CalendarViewController.swift
////  RedMoon2021
////
////  Created by 上田晃 on 2021/09/10
//
//import UIKit
//import FSCalendar
//import RxSwift
//import RxCocoa
//import PKHUD
//import Firebase//VCの持ち物じゃない
////import FirebaseFirestore//VCの持ち物じゃない
//import ViewAnimator
//import AudioToolbox
//import CalculateCalendarLogic
//import GoogleMobileAds//サポート
////import FirebaseDatabase//VCの持ち物じゃない
//import SafariServices
//import AlamofireImage
//
//final class CalendarViewController: UIViewController, FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance, UITabBarDelegate {//スライド出ていない
//    private let disposeBag = DisposeBag()
//    private let cellId = "cellId"
//    private let scrollLabel = AutoScrollLabel()
//    private let layout = UICollectionViewFlowLayout()
//    private let AdMobID = "ca-app-pub-6401379776966995/5061322972"
//    private let calendarViewModel: CalendarViewModelType
//    private var authHandle: AuthStateDidChangeListenerHandle!//FireBase依存
//    private var retryCount = 0
//    private var rxOtokuArray = [OtokuDataModel]()//UIの持ち物じゃない
//    private var calenderModel = CalendarModel()//不要
//
//    deinit{
//        Auth.auth().removeStateDidChangeListener(authHandle)//FireBase依存
//    }
//    @IBOutlet weak var scrollBaseView: UIView!
//    @IBOutlet var calendar: FSCalendar!
//    @IBOutlet weak var otokuCollectionView: UICollectionView!
//    @IBOutlet weak var emptyView: UIView!
//    @IBOutlet weak var bannerView: UIView!
//    // MARK: - リスナーを設定
//    required init?(coder: NSCoder) {
//        calendarViewModel = CalendarViewModel(model: calenderModel)//不要　ここにモックを差し込む（ちなみにVCも抽象化でテスト可能。UIテスト）
//        super.init(coder: coder)
//        checkVersion()
//        authStateCheck()//check
//    }
//    // MARK: - viewDidLayoutSubviews（横にcell３つまで）
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        CalenderColectionViewLayout.calendarCollectionViewLayout(view: self.view, layout: layout)//Static　VCより　VM
//    }
//    // MARK: - viewWillLayoutSubviews
//    override func viewWillLayoutSubviews() {
//        super.viewWillLayoutSubviews()
//        CalendarsLayout.calendarsLayout(calendar: calendar)//Static VCより　VM
//    }
//    // MARK: - viewDidLoad
//    override func viewDidLoad() {
//        super.viewDidLoad()
////        scrollBaseView.addSubview(scrollLabel)
//        // MARK: - Rx
//        calendarViewModel
//            .output
//            .showableInfosObservable
//            .observe(on: MainScheduler.instance)
//            .subscribe(onNext: {  [weak self] data in
//                guard let strongSelf = self else { return }
//                strongSelf.otokuCollectionView.isHidden = data.count == .zero//ロジック？  VM isShowカレンダーとか
//                strongSelf.emptyView.isHidden = data.count > .zero
//                strongSelf.rxOtokuArray = data
//                strongSelf.otokuCollectionView.reloadData()
//            })
//            .disposed(by: disposeBag)
//
//        calendarViewModel
//            .output
//            .scrollTitleObservable
//            .observe(on: MainScheduler.instance)
//            .subscribe(onNext: { [weak self]   data in
////                guard let strongSelf = self else { return }
//                self!.scrollLabel.textColor = .black
//                self!.scrollLabel.backgroundColor = .white
//                var scrollWord = "日付をタップすると情報が切り替わります。　　　　　　　　　         　 　　　　　　【本日のお得情報】"//ロジック　VM
//                for i in 0 ..< data.count {
//                    scrollWord += "\(data[i].title)　　　"
//                }
//                self!.scrollLabel.text = scrollWord
//            })
//            .disposed(by: disposeBag)
//
//        calendarViewModel
//            .output
//            .isLoadingObservable
//            .subscribe(onNext: { isLoading in
//                isLoading ? HUD.show(.progress) : HUD.hide()
//            })
//            .disposed(by: disposeBag)
//        // MARK: -AdMob
//        SetAdMobModel.setAdMob(bannerView: self.bannerView, view: self.view, Self: self)//Static　VC  一目でわからない　自由度が髙杉（etc）　　input outputどちらも
//        // MARK: -
//        self.view.backgroundColor = .systemRed
//        self.calendar.delegate = self//selfをクラス変更
//        self.calendar.dataSource = self
//        otokuCollectionView.delegate = self
//        otokuCollectionView.dataSource = self
//        otokuCollectionView.collectionViewLayout = layout
//        otokuCollectionView.register(UINib(nibName: "OtokuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: cellId)
//    }// viewDidLoadここまで
//
//    // MARK: - viewWillAppear
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        self.navigationController?.isNavigationBarHidden = true
//
//        scrollBaseView.addSubview(scrollLabel)
//        self.scrollLabel.text = "あいうえお"
//    }
//    // MARK: -
//    func authStateCheck(){
//        calendarViewModel
//            .output
//            .authObservable
//            .subscribe (onNext: { [weak self] auth in
//                self?.authHandle = auth
//                print("check",auth)
//            })
//            .disposed(by: disposeBag)
//    }
//    // MARK: - カレンダーデリゲートメソッド
//    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
//        AudioServicesPlaySystemSound(1519)//VC 震えの種類を変えるなど
//        calendarViewModel.input.selectDateObserver.onNext(date)
//    }
//    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
//        calendar.reloadData()
//    }
//    // 土日や祝日の日の文字色を変える
//    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
//        if calendar.scope == .month {//VM
//            //  現在表示されているページの月とセルの月が異なる場合には nil を戻す
//            if Calendar.current.compare(date, to: calendar.currentPage, toGranularity: .month) != .orderedSame {
//                return nil
//            }
//        }
//        //祝日判定をする（祝日は赤色で表示する）
//        if CalendarsLayout.judgeHoliday(date){
//            return UIColor.red
//        }
//        //土日の判定を行う（土曜日は青色、日曜日は赤色で表示する）
//        let weekday = CalendarsLayout.getWeekIdx(date)
//        if weekday == 1 {   //日曜日
//            return UIColor.red
//        }
//        else if weekday == 7 {  //土曜日
//            return UIColor.systemBlue
//        }
//        return nil
//    }
//}
//
//// MARK: -UICollectionViewDelegate, UICollectionViewDataSource
//
//extension CalendarViewController:UICollectionViewDelegate, UICollectionViewDataSource {
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return rxOtokuArray.count  //デリゲートをVM
//    }
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {//question
//        let cell = otokuCollectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! OtokuCollectionViewCell
//        CalenderColectionViewLayout.CalenderColectionViewLayout(cell: cell, rxOtokuArray: rxOtokuArray, indexPath: indexPath)
//        return cell
//    }
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {//入力と出力？　indexPath
//        AudioServicesPlaySystemSound(1519)
//        let selectedWebPage = rxOtokuArray[indexPath.row].blog_web_url//デリゲートをRx
//        guard let url = URL(string: selectedWebPage) else {return}
//        let safariView = SFSafariViewController(url: url)
//        present(safariView, animated: true)
//    }
//    func didSelectTab(tabBarController: BaseTabBarController) {
//        AudioServicesPlaySystemSound(1519)
//    }
//}
//private extension CalendarViewController {//切り分け
//    func checkVersion() {
//        AppStore.checkVersion { (isOlder: Bool) in
//            guard isOlder else { return }
//            let alertController = UIAlertController(title: "新しいバージョンがあります!", message: "アップデートお願い致します。", preferredStyle: .alert)
//            alertController.addAction(UIAlertAction(title: "アップデート", style: .default) { action in
//                AppStore.open()
//            })
//            alertController.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
//            self.present(alertController, animated: true)
//        }
//    }
//}
