//
//  CalendarViewModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2023/01/10.
//

import Foundation
import RxSwift
import RxCocoa
import RxRelay
import Firebase
import FirebaseAuth
import GoogleMobileAds


protocol CalendarViewModelInput {
    var calendarSelectedDateObserver: AnyObserver<Date> { get }
    var viewWidthSizeObserver: AnyObserver<SetAdMobModelData> { get }
    var collectionViewSelectedIndexPathObserver: AnyObserver<IndexPath> { get }
    var scrollBaseViewsBoundsObservable: AnyObserver<CGRect> { get }
}
protocol CalendarViewModelOutput {
    var showableInfosObservable: Observable<[OtokuDataModel]> { get }
    var authStateObservable:Observable<AuthStatus> { get }
    var isLoadingObservable:Observable<Bool> { get }
    var setAdMobBannerObservable: Observable<GADBannerView> { get }
    var collectionViewSelectedUrlObservable: Observable<String> { get }
    var autoScrollModelObservable: Observable<AutoScrollModel> { get }
}
protocol CalendarViewModelType {
    var input: CalendarViewModelInput { get }
    var output: CalendarViewModelOutput { get }
}
// MARK: -
final class CalendarViewModel{
    //input
    private let calendarSelectedDateSubject = BehaviorSubject<Date>(value: Date())
    private let viewWidthSizeSubject = PublishSubject<SetAdMobModelData>()
    private let collectionViewSelectedIndexPathSubject = PublishSubject<IndexPath>()
    private let articlesSubject = BehaviorSubject<[OtokuDataModel]>(value: [])
    private let scrollBaseViewBoundsSubject = PublishSubject<CGRect>()
    private let autoScrollModelsLayoutSubject = PublishSubject<AutoScrollModel>()
    private let autoScrollViewSubject = PublishSubject<AutoScrollModel>()
    //output
    private let showableInfosRelay = BehaviorRelay<[OtokuDataModel]>(value: [])
    private let authStateSubject = PublishSubject<AuthStatus>()
    private let scrollViewsTitleSubject = BehaviorSubject<[ScrollModel]>(value: [])
    private let isLoadingSubject = PublishSubject<Bool>()
    private let setAdMobBannerlRelay = PublishRelay<GADBannerView>()
    private let collectionViewSelectedUrlRelay = BehaviorRelay<String>(value: "")
    
    let todayDateModel: FetchTodayDateModelType
    let calendarModel: CalendarModelType
    let setAdMobModel: SetAdMobModelType
    let autoScroll: AutoScrollModelType
    let CommonDataModel: FetchCommonDataModelType
    let disposeBag = DisposeBag()
    
    // Initializer
    init?(calendarViewModel: CalendarModelType,adMobModel: SetAdMobModelType,fetchTodayDateModel: FetchTodayDateModelType,autoScrollModel: AutoScrollModelType,fetchCommonDataModel: FetchCommonDataModelType) {
        
        self.calendarModel = calendarViewModel
        self.setAdMobModel = adMobModel
        self.todayDateModel = fetchTodayDateModel
        self.autoScroll = autoScrollModel
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let commonDataModel = appDelegate.container.resolve(FetchCommonDataModelType.self) else {
            return nil
        }
        CommonDataModel = commonDataModel
        
        calendarModel.input.authState()
        
        viewWidthSizeSubject
            .subscribe { [self] size in
                setAdMobModel.setAdMob(viewWidthSize: size.element?.size ?? 0, Self: size.element!.VC)
            }
            .disposed(by: disposeBag)
        
        setAdMobModel
            .output
            .SetAdMobModelObservable
            .subscribe { [self] setAdMob in
                setAdMobBannerlRelay.accept(setAdMob)
            }
            .disposed(by: disposeBag)
        
        CommonDataModel
            .output
            .fetchCommonDataModelObservable
            .subscribe { [self] data in
                articlesSubject.onNext(data)
            }
            .disposed(by: disposeBag)
        
        calendarModel
            .output
            ._authStatusObserbable
            .subscribe { [self] auth in
                switch auth {
                case .anonymous:
                    CommonDataModel.input.bindFetchData()
                    authStateSubject.onNext(auth)
                case .error(let message):
                    print(message)
                    CommonDataModel.input.bindFetchData()
                    CommonDataModel.input.updateUIFromRealmData()
                default:
                    break
                }
            }
            .disposed(by: disposeBag)
        
        func showAlert(message: String) {
        }
        scrollBaseViewBoundsSubject
            .map({ [self] viewsBounds in
                autoScroll
                    .input
                    .autoScrollLabelLayoutArrange(scrollLabel: autoScroll as! AutoScrollModel , scrollBaseViewsBounds: viewsBounds)
            })
            .bind(to: autoScrollModelsLayoutSubject)
            .disposed(by: disposeBag)
        
        collectionViewSelectedIndexPathSubject
            .withLatestFrom(showableInfosRelay) { indexPath, data in
                (indexPath, data)
            }
            .filter { _, data in
                !data.isEmpty
            }
            .map { indexPath, data in
                let selectedUrl = data[indexPath.row].blog_web_url
                return selectedUrl
            }
            .bind(to: collectionViewSelectedUrlRelay)
            .disposed(by: disposeBag)
        
        Observable
            .combineLatest(calendarSelectedDateSubject.asObservable(),showableInfosRelay.asObservable(),autoScrollModelsLayoutSubject.asObservable())
            .map { [self]selectedDate, title, layout  in
                let selected = formatDate(date: selectedDate)
                let scrollWord = "【\(selected)のお得情報】" + title.map { $0.article_title }.joined(separator: "　　　")
                layout.text = scrollWord
                return layout
            }
            .bind(to: autoScrollViewSubject)
            .disposed(by: disposeBag)
        
        Observable
            .merge(
                calendarSelectedDateSubject
                    .map { _ in true }
                    .debug("selectDateSubject"),
                showableInfosRelay
                    .map { _ in false }
                    .debug("articlesSubject")
            )
            .debug("bind")
            .bind(to: isLoadingSubject)
            .disposed(by: disposeBag)
        
        Observable.combineLatest(calendarSelectedDateSubject.asObservable(), articlesSubject.asObservable())
            .map { [self]  selectDate, data in
                data.filter { checkEnabledDate($0, date: selectDate) }
                    .shuffled()
            }
            .bind(to: showableInfosRelay)
            .disposed(by: disposeBag)
    }
    //MARK: -
    ///スクロールラベル用　"M月d日"変換関数
    private  func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
    ///選択日のコレクションビュー表示用、選別関数
    private  func checkEnabledDate(_ data: OtokuDataModel, date: Date) -> Bool {
        let (weekdayString, dateString) = format(date: date)
        let addZeroDate = addZeroTapString(date: date)
        return data.enabled_dates.contains(where: { $0 == addZeroDate || $0 == weekdayString || $0 == dateString })
    }
    ///選択日のコレクションビュー表示用、曜日、単発日付
    private  func format(date: Date) -> (String, String) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "EEEE"
        let weekdayString = formatter.string(from: date)
        formatter.dateFormat = "yyyyMMdd"
        let dateString = formatter.string(from: date)
        return (weekdayString, dateString)
    }
    ///選択日のコレクションビュー表示用、ゼロ付日付
    private func addZeroTapString(date:Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MM-dd-YYYY"
        let tmpDate = Calendar(identifier: .gregorian)
        let tapDayInt = tmpDate.component(.day, from: date)
        let addZeroTapDay = String(format: "%02d", tapDayInt)
        return addZeroTapDay
    }
}
//MARK: - ViewModel Extension
extension CalendarViewModel:CalendarViewModelInput{
    var scrollBaseViewsBoundsObservable: RxSwift.AnyObserver<CGRect> {
        return scrollBaseViewBoundsSubject.asObserver()
    }
    var collectionViewSelectedIndexPathObserver: AnyObserver<IndexPath> {
        return collectionViewSelectedIndexPathSubject.asObserver()
    }
    var viewWidthSizeObserver: AnyObserver<SetAdMobModelData> {
        return viewWidthSizeSubject.asObserver()
    }
    var calendarSelectedDateObserver: AnyObserver<Date> {
        return calendarSelectedDateSubject.asObserver()
    }
}
extension CalendarViewModel:CalendarViewModelOutput{
    var autoScrollModelObservable: RxSwift.Observable<AutoScrollModel> {
        return autoScrollViewSubject.asObservable()
    }
    var collectionViewSelectedUrlObservable: Observable<String> {
        return collectionViewSelectedUrlRelay.asObservable()
    }
    var setAdMobBannerObservable: Observable<GADBannerView> {
        return setAdMobBannerlRelay.asObservable()
    }
    var showableInfosObservable: Observable<[OtokuDataModel]> {
        return showableInfosRelay.asObservable()
    }
    var authStateObservable: Observable<AuthStatus>{
        return authStateSubject.asObservable()
    }
    var isLoadingObservable: Observable<Bool> {
        return isLoadingSubject.asObservable()
    }
}
extension CalendarViewModel: CalendarViewModelType {
    var input: CalendarViewModelInput { return self }
    var output: CalendarViewModelOutput { return self }
}
