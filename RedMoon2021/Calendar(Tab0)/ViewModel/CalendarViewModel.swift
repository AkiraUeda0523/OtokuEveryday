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
import MachO

// MARK: - Protocols
// ビューモデルの入力と出力に関するプロトコル定義
protocol CalendarViewModelInput {
    // カレンダー上で選択された日付を監視するObserver
    var calendarSelectedDateObserver: AnyObserver<Date> { get }
    // ビューの幅サイズ情報を監視するObserver
    var viewWidthSizeObserver: AnyObserver<SetAdMobModelData> { get }
    // コレクションビューで選択されたIndexPathを監視するObserver
    var collectionViewSelectedIndexPathObserver: AnyObserver<IndexPath> { get }
    // スクロールベースビューの境界矩形を監視するObserver
    var scrollBaseViewsBoundsObservable: AnyObserver<CGRect> { get }
}
protocol CalendarViewModelOutput {
    // 表示可能な情報を提供するObservable
    var showableInfosObservable: Observable<[OtokuDataModel]> { get }
    // 認証状態を提供するObservable
    var authStateObservable: Observable<AuthStatus> { get }
    // ローディング状態を提供するObservable
    var isLoadingObservable: Observable<Bool> { get }
    // AdMobバナーの設定情報を提供するObservable
    var setAdMobBannerObservable: Observable<GADBannerView> { get }
    // コレクションビューで選択されたURLを監視するObservable
    var collectionViewSelectedUrlObservable: Observable<String> { get }
    // 自動スクロールモデルの情報を提供するObservable
    var autoScrollModelObservable: Observable<AutoScrollModelType> { get }
}
protocol CalendarViewModelType {
    // ビューモデルの入力と出力をまとめたプロトコル
    var input: CalendarViewModelInput { get }
    var output: CalendarViewModelOutput { get }
}
// MARK: - Main Class
final class CalendarViewModel {
    // input
    internal let calendarSelectedDateSubject = BehaviorSubject<Date>(value: Date())
    internal let viewWidthSizeSubject = PublishSubject<SetAdMobModelData>()
    internal let collectionViewSelectedIndexPathSubject = PublishSubject<IndexPath>()
    internal let articlesSubject = BehaviorSubject<[OtokuDataModel]>(value: [])
    
    internal let scrollBaseViewBoundsSubject = PublishSubject<CGRect>()
    internal let autoScrollModelsLayoutSubject = PublishSubject<AutoScrollModelType>()
    internal let autoScrollViewSubject = PublishSubject<AutoScrollModelType>()
    // output
    internal let showableInfosRelay = BehaviorRelay<[OtokuDataModel]>(value: [])
    internal let authStateSubject = PublishSubject<AuthStatus>()
    private let scrollViewsTitleSubject = BehaviorSubject<[ScrollModel]>(value: [])
    private let isLoadingSubject = PublishSubject<Bool>()
    private let setAdMobBannerlRelay = PublishRelay<GADBannerView>()
    internal let collectionViewSelectedUrlRelay = PublishSubject<String>()
    let authenticationManager: AuthenticationManagerType
    let adMobModel: SetAdMobModelType
    let todayDateModel: FetchTodayDateModelType
    let autoScrollModel: AutoScrollModelType
    let commonDataModel: FetchCommonDataModelType
    let disposeBag = DisposeBag()
    // Initializer
    init?(authenticationManager: AuthenticationManagerType, adMobModel: SetAdMobModelType, todayDateModel: FetchTodayDateModelType, autoScrollModel: AutoScrollModelType, commonDataModel: FetchCommonDataModelType) {
        // 認証マネージャータイプ、AdMobモデルタイプ、日付モデルタイプ、自動スクロールモデルタイプ、共通データモデルタイプの依存性を受け取り、プロパティに設定
        self.authenticationManager = authenticationManager
        self.adMobModel = adMobModel
        self.todayDateModel = todayDateModel
        self.autoScrollModel = autoScrollModel
        self.commonDataModel = commonDataModel
        // MARK: -Auth（行き）　ユーザーの認証状態チェックトリガー
        self.authenticationManager
            .input
            .initializeAuthStateListener()
        // MARK: -Auth（帰り）　認証状態に応じてデータを取得
        self.authenticationManager
            .output
            .authStatusObservable
            .withUnretained(self) // 'self' を 'owner' として扱う
            .flatMap { owner, authStatus -> Observable<AuthStatus> in
                return Observable.create { observer in
                    Task {
                        switch authStatus {
                        case .anonymous:
                            await owner.commonDataModel.input.isRealmDataEmpty() // Realmデータの確認
                            observer.onNext(authStatus) // 次の状態に進む
                        case .error:
                            await owner.commonDataModel.input.isRealmDataEmpty()
                            owner.commonDataModel.input.updateUIFromRealmData() // UI更新
                            observer.onNext(authStatus)
                        case .retrying:
                            observer.onNext(authStatus)
                        }
                    }
                    return Disposables.create() // リソースをクリーンアップ
                }
            }
            .subscribe { [weak self] authStatus in
                self?.authStateSubject.onNext(authStatus) // authStatus を更新
            }
            .disposed(by: disposeBag)
        // MARK: -Data メインデータを取得
        self.commonDataModel
            .output
            .fetchCommonDataModelObservable
            .subscribe { [self] data in
                articlesSubject.onNext(data)
            }
            .disposed(by: disposeBag)
        // MARK: -　選択日からデータの選別
        // 日付フォーマッタを設定
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            return formatter
        }()
        // 現在の時間を文字列で取得する関数
        func currentTimeString() -> String {
            return dateFormatter.string(from: Date())
        }
        Observable
            .combineLatest(
                calendarSelectedDateSubject.asObservable().do(onNext: { date in
                }),
                articlesSubject.asObservable()
            )
            .map { [self] selectDate, data in
                let filteredData = data.filter { checkEnabledDate($0, date: selectDate) }
                return filteredData.shuffled()
            }
            .do(onNext: { _ in
            })
            .bind(to: showableInfosRelay)
            .disposed(by: disposeBag)
        // MARK: - コレクションビューで選択されたIndexPathのURLを通知
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
            .do(onNext: { url in
            })
            .bind(to: collectionViewSelectedUrlRelay)
            .disposed(by: disposeBag)
        // MARK: -ScrollView　スクロール用タイトル取得
        Observable//reduce(into:版
            .combineLatest(calendarSelectedDateSubject.asObservable(), showableInfosRelay.asObservable(), autoScrollModelsLayoutSubject.asObservable())
            .filter { _, title, _ in !title.isEmpty } // titleが空でない場合のみ通過させる
            .map { [self] selectedDate, title, layout in
                let selected = formatDate(date: selectedDate)
                let scrollWord_reduce_into = title.reduce(into: "【\(selected)のお得情報】") { result, article in
                    result += article.article_title + "　　　"
                }.trimmingCharacters(in: .whitespaces)
                let mutableLayout = layout
                mutableLayout.text = scrollWord_reduce_into
                return mutableLayout
            }
            .bind(to: autoScrollViewSubject)
            .disposed(by: disposeBag)
        // MARK: -ScrollLabel作成の為にVCからWidthSizeの通知を受け取る
        scrollBaseViewBoundsSubject
            .map({ viewsBounds in
                return self.autoScrollModel.input.autoScrollLabelLayoutArrange(scrollBaseViewsBounds: viewsBounds)
            })
            .bind(to: autoScrollModelsLayoutSubject)
            .disposed(by: disposeBag)
        // MARK: -AdMob　バナー作成の為にVCからWidthSizeの通知を受け取る
        viewWidthSizeSubject
            .subscribe {  size in
                adMobModel
                    .setAdMob(bannerWidthSize: size.element?.bannerWidth ?? 0,bannerHeight: size.element?.bannerHeight ?? 0, viewController: size.element!.VC)
            }
            .disposed(by: disposeBag)
        //        // MARK: -AdMob　出来上がったAdMobバナーの設定
        self.adMobModel
            .output
            .SetAdMobModelObservable
            .subscribe { [self] (setAdMob: AdBannerView) in
                setAdMobBannerlRelay.accept(setAdMob as! GADBannerView)
            }
            .disposed(by: disposeBag)
        // MARK: -インジケーター用の状態監視
        calendarSelectedDateSubject
            .do(onNext: { _ in
            })
            .map { _ in true }
            .flatMapLatest { isLoading -> Observable<Bool> in
                Observable<Bool>.create { observer in
                    observer.onNext(true)  // まず確実にtrueを発行
                    // 少し遅延を入れてfalseを発行
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        observer.onNext(false)
                    }
                    return Disposables.create()
                }
            }
            .bind(to: isLoadingSubject)
            .disposed(by: disposeBag)
    }
    // MARK: -
    /// スクロールラベル用　"M月d日"変換関数
    private  func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
    /// 選択日のコレクションビュー表示用、選別関数
    private  func checkEnabledDate(_ data: OtokuDataModel, date: Date) -> Bool {
        let (weekdayString, dateString) = format(date: date)
        let addZeroDate = addZeroTapString(date: date)
        return data.enabled_dates.contains(where: { $0 == addZeroDate || $0 == weekdayString || $0 == dateString })
    }
    /// 選択日のコレクションビュー表示用、曜日、単発日付
    private  func format(date: Date) -> (String, String) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "EEEE"
        let weekdayString = formatter.string(from: date)
        formatter.dateFormat = "yyyyMMdd"
        let dateString = formatter.string(from: date)
        return (weekdayString, dateString)
    }
    /// 選択日のコレクションビュー表示用、ゼロ付日付
    private func addZeroTapString(date:Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MM-dd-YYYY"
        let tmpDate = Calendar(identifier: .gregorian)
        let tapDayInt = tmpDate.component(.day, from: date)
        let addZeroTapDay = String(format: "%02d", tapDayInt)
        return addZeroTapDay
    }
}
// MARK: - Input Implementation
extension CalendarViewModel: CalendarViewModelInput {
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
// MARK: - Output Implementation
extension CalendarViewModel: CalendarViewModelOutput {
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
    var authStateObservable: Observable<AuthStatus> {
        return authStateSubject.asObservable()
    }
    var isLoadingObservable: Observable<Bool> {
        return isLoadingSubject.asObservable()
    }
}
// MARK: - Additional Extensions
extension CalendarViewModel: CalendarViewModelType {
    // ビューモデルの入力プロトコルを実装
    var input: CalendarViewModelInput { return self }
    // ビューモデルの出力プロトコルを実装
    var output: CalendarViewModelOutput { return self }
}
