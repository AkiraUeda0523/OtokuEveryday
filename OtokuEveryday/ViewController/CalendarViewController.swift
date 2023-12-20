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
    // MARK: - リスナーを設定
    required init?(coder: NSCoder) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let calendarViewModel = appDelegate.container.resolve(CalendarViewModel.self) else {
            return nil
        }
        self.calendarViewModel = calendarViewModel
        super.init(coder: coder)
        print("Constructor called: \(self)")  // ログの追加
        print("⭐️",Thread.callStackSymbols)  // スタックトレースの出力
        checkVersion()
        authStateCheck()
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
        setAutoScrollView()
    }
    // MARK: -
    private func setAutoScrollView(){
        calendarViewModel
            .output
            .autoScrollModelObservable
            .subscribe { event in
                switch event {
                case .next(let scrollView as UIView):
                    self.scrollBaseView.addSubview(scrollView)
                default:
                    break
                }
            }
            .disposed(by: disposeBag)
        
        calendarViewModel.input.scrollBaseViewsBoundsObservable.onNext(self.scrollBaseView.bounds)
    }
    private func setAdMobBanner(){
        calendarViewModel
            .output
            .setAdMobBannerObservable
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] setAdMob in
                self?.bannerView.addSubview(setAdMob)
            })
            .disposed(by: disposeBag)
        
        calendarViewModel
            .input
            .viewWidthSizeObserver
            .onNext(SetAdMobModelData(bannerWidth: self.view.frame.width, bannerHight: self.bannerView.frame.height, VC: self))
    }
    
    private func collectionViewObserveList() {
        otokuCollectionView.delegate = nil
        otokuCollectionView.dataSource = nil
        calendarViewModel
            .output
            .showableInfosObservable
            .debug("流れてくる")
            .observe(on: MainScheduler.instance)
            .bind(to: otokuCollectionView.rx.items(cellIdentifier: cellId, cellType: OtokuCollectionViewCell.self)) { row, element, cell in
                cell.otokuLabel.text = element.article_title
                let url = URL(string: element.collectionView_image_url) ?? URL(string: self.defaultImageUrl)!
                if url.absoluteString == self.defaultImageUrl {
                    cell.otokuImage.contentMode = .scaleAspectFit
                } else {
                    cell.otokuImage.contentMode = .scaleAspectFill
                }
                cell.otokuImage.af.setImage(withURL: url, imageTransition: .crossDissolve(0.5))
            }
            .disposed(by: disposeBag)
    }
    
    private func collectionViewDidTap() {
        otokuCollectionView.rx.itemSelected
            .subscribe(onNext: { [unowned self] indexPath in
                self.otokuCollectionView.deselectItem(at: indexPath, animated: true)
                AudioServicesPlaySystemSound(1519)
                calendarViewModel.input.collectionViewSelectedIndexPathObserver.onNext(indexPath)
            })
            .disposed(by: disposeBag)
        
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
    private func isLoadingAction(){
        calendarViewModel
            .output
            .showableInfosObservable
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: {  [weak self] data in
                guard let strongSelf = self else { return }
                strongSelf.otokuCollectionView.isHidden = data.count == .zero
                strongSelf.emptyView.isHidden = data.count > .zero
            })
            .disposed(by: disposeBag)
        
        calendarViewModel
            .output
            .isLoadingObservable
            .subscribe(onNext: { isLoading in
                isLoading ? HUD.show(.progress) : HUD.hide()
            })
            .disposed(by: disposeBag)
    }
    @objc func titleLabelTapped() {
        AudioServicesPlaySystemSound(1519)
        let currentDate = Date()
        calendarViewModel.input.calendarSelectedDateObserver.onNext(currentDate)
        self.calendar.select(currentDate)
        otokuCollectionView.setContentOffset(CGPoint(x: 0, y: -otokuCollectionView.contentInset.top), animated: true)
        setup()
        setAutoScrollView()
        print("titleLabel was tapped!")
    }
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        print("tab was tapped!")
        if let navController = viewController as? UINavigationController {
            if let topVC = navController.topViewController, topVC is CalendarViewController {
                // タップされたタブのルートが SomeSpecificViewController だった場合の処理
                titleLabelTapped()
            }
        }
        return true
    }
    func setup() {
        setAdMobBanner()
        isLoadingAction()
        collectionViewDidTap()
        self.view.backgroundColor = .systemRed
        self.calendar.delegate = self
        self.calendar.dataSource = self
        otokuCollectionView.collectionViewLayout = layout
        otokuCollectionView.register(UINib(nibName: "OtokuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: cellId)
    }
    // MARK: -Layout
    private func calendarCollectionViewLayout(view:UIView,layout:UICollectionViewFlowLayout){
        let width = view.frame.width
        layout.itemSize = CGSize(width: (width - 20)/3 , height: (width - 20)/3)
    }
    private func calendarsLayout(calendar:FSCalendar){
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
    func judgeHoliday(_ date : Date) -> Bool {
        let tmpCalendar = Calendar(identifier: .gregorian)
        let year = tmpCalendar.component(.year, from: date)
        let month = tmpCalendar.component(.month, from: date)
        let day = tmpCalendar.component(.day, from: date)
        let holiday = CalculateCalendarLogic()
        return holiday.judgeJapaneseHoliday(year: year, month: month, day: day)
    }
    func getWeekIdx(_ date: Date) -> Int{
        let tmpCalendar = Calendar(identifier: .gregorian)
        return tmpCalendar.component(.weekday, from: date)
    }
    // MARK: - CalendarsDelegateMethods
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        AudioServicesPlaySystemSound(1519)
        calendarViewModel.input.calendarSelectedDateObserver.onNext(date)
        otokuCollectionView.setContentOffset(CGPoint(x: 0, y: -otokuCollectionView.contentInset.top), animated: true)
    }
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        calendar.reloadData()
    }
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
        if calendar.scope == .month {//VM
            if Calendar.current.compare(date, to: calendar.currentPage, toGranularity: .month) != .orderedSame {
                return nil
            }
        }
        if judgeHoliday(date){
            return UIColor.red
        }
        let weekday = getWeekIdx(date)
        if weekday == 1 {
            return UIColor.red
        }
        else if weekday == 7 {
            return UIColor.systemBlue
        }
        return nil
    }
}
// MARK: -extension init function
private extension CalendarViewController {
    private  func checkVersion() {
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
    private func authStateCheck() {
        calendarViewModel
            .output
            .authStateObservable
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] auth in
                guard let self = self else { return }
                switch auth {
                case .anonymous:
                    PKHUD.sharedHUD.hide()
                    calendarCollectionViewLayout(view: self.view, layout: layout)
                    calendarsLayout(calendar: calendar)
                    collectionViewObserveList()
                    print("匿名でログインしています")
                case .error(let message):
                    PKHUD.sharedHUD.hide()
                    print(message)
                    let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alertController, animated: true, completion: nil)
                case .retrying:
                    PKHUD.sharedHUD.show()
                }
            })
            .disposed(by: disposeBag)
    }
}
