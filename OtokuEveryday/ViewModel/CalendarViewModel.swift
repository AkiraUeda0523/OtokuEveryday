//
//  CalendarViewModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2023/01/10.
//

import Foundation
import RxSwift
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
    var autoScrollModelObservable: Observable<AutoScrollModelType> { get }
}
protocol CalendarViewModelType {
    var input: CalendarViewModelInput { get }
    var output: CalendarViewModelOutput { get }
}
// MARK: -
final class CalendarViewModel{
    //input
    internal let calendarSelectedDateSubject = BehaviorSubject<Date>(value: Date())
    internal let viewWidthSizeSubject = PublishSubject<SetAdMobModelData>()
    internal let collectionViewSelectedIndexPathSubject = PublishSubject<IndexPath>()
    internal let articlesSubject = BehaviorSubject<[OtokuDataModel]>(value: [])
    internal let scrollBaseViewBoundsSubject = PublishSubject<CGRect>()
    internal let autoScrollModelsLayoutSubject = PublishSubject<AutoScrollModelType>()
    internal let autoScrollViewSubject = PublishSubject<AutoScrollModelType>()
    //output
    internal let showableInfosRelay = BehaviorRelay<[OtokuDataModel]>(value: [])
    internal let authStateSubject = PublishSubject<AuthStatus>()
    private let scrollViewsTitleSubject = BehaviorSubject<[ScrollModel]>(value: [])
    private let isLoadingSubject = PublishSubject<Bool>()
    private let setAdMobBannerlRelay = PublishRelay<GADBannerView>()
    internal let collectionViewSelectedUrlRelay = PublishSubject<String>()
    
    let calendarModel: CalendarModelType
    let adMobModel: SetAdMobModelType
    let todayDateModel: FetchTodayDateModelType
    let autoScrollModel: AutoScrollModelType
    let commonDataModel: FetchCommonDataModelType
    let disposeBag = DisposeBag()
    
    
    init?(calendarModel: CalendarModelType, adMobModel: SetAdMobModelType, todayDateModel: FetchTodayDateModelType, autoScrollModel: AutoScrollModelType, commonDataModel: FetchCommonDataModelType) {
        
        self.calendarModel = calendarModel
        self.adMobModel = adMobModel
        self.todayDateModel = todayDateModel
        self.autoScrollModel = autoScrollModel
        self.commonDataModel = commonDataModel
        
        
        viewWidthSizeSubject
            .subscribe {  size in
                adMobModel.setAdMob(bannerWidthSize: size.element?.bannerWidth ?? 0,bannerHight: size.element?.bannerHight ?? 0, viewController: size.element!.VC)
            }
            .disposed(by: disposeBag)
        
        adMobModel
            .output
            .SetAdMobModelObservable
            .subscribe { [self] (setAdMob: AdBannerView) in
                setAdMobBannerlRelay.accept(setAdMob as! GADBannerView)
            }
            .disposed(by: disposeBag)
        
        
        commonDataModel
            .output
            .fetchCommonDataModelObservable
            .subscribe { [self] data in
                articlesSubject.onNext(data)
            }
            .disposed(by: disposeBag)
        
        calendarModel
            .output
            ._authStatusObserbable
            .do(onNext: { print("⚠️",$0) })
            .flatMap { [weak self] authStatus -> Observable<AuthStatus> in
                guard let self = self else { return .empty() }
                return Observable.create { observer in
                    Task {
                        switch authStatus {
                        case .anonymous:
                            await self.commonDataModel.input.bindFetchData()
                            observer.onNext(authStatus)
                        case .error:
                            await
                            self.commonDataModel.input.bindFetchData()
                            
                            await self.commonDataModel.input.updateUIFromRealmData()
                            
                            observer.onNext(authStatus)
                        case .retrying:
                            observer.onNext(authStatus)
                            
                        }
                    }
                    return Disposables.create()
                }
            }
            .observe(on: MainScheduler.instance)
            .subscribe { [weak self] authStatus in
                print("Current Thread: \(Thread.current)")
                self?.authStateSubject.onNext(authStatus)
            }
            .disposed(by: disposeBag)
        
        scrollBaseViewBoundsSubject
            .map({ viewsBounds in
                return self.autoScrollModel.input.autoScrollLabelLayoutArrange(scrollBaseViewsBounds: viewsBounds)
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
                assert(Thread.isMainThread)
                let selectedUrl = data[indexPath.row].blog_web_url
                return selectedUrl
            }
            .do(onNext: { url in
                print("URL before binding: \(url)")
            })
            .observe(on: MainScheduler.instance)
            .bind(to: collectionViewSelectedUrlRelay)
            .disposed(by: disposeBag)
        
        Observable
            .combineLatest(calendarSelectedDateSubject.asObservable(),showableInfosRelay.asObservable(),autoScrollModelsLayoutSubject.asObservable())
            .map { [self]selectedDate, title, layout  in
                let selected = formatDate(date: selectedDate)
                let scrollWord = "【\(selected)のお得情報】" + title.map { $0.article_title }.joined(separator: "　　　")
                var mutableLayout = layout
                mutableLayout.text = scrollWord
                return mutableLayout
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
        
        
        calendarModel.input.authState()
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
    var autoScrollModelObservable: RxSwift.Observable<AutoScrollModelType> {
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

