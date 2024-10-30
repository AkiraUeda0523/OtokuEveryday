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
    var authStateObservable: Observable<AuthStatus> { get }
    var isLoadingObservable: Observable<Bool> { get }
    var setAdMobBannerObservable: Observable<GADBannerView> { get }
    var collectionViewSelectedUrlObservable: Observable<String> { get }
    var autoScrollModelObservable: Observable<AutoScrollModel> { get }
}
protocol CalendarViewModelType {
    var input: CalendarViewModelInput { get }
    var output: CalendarViewModelOutput { get }
}
// MARK: -
final class CalendarViewModel {// テストとはinput走らせてoutput発火するか。それだけ
    // input
    private let calendarSelectedDateSubject = BehaviorSubject<Date>(value: Date())// 初期値today
    private let viewWidthSizeSubject = PublishSubject<SetAdMobModelData>()
    private let collectionViewSelectedIndexPathSubject = PublishSubject<IndexPath>()
    private let articlesSubject = BehaviorSubject<[OtokuDataModel]>(value: [])
    private let scrollBaseViewBoundsSubject = PublishSubject<CGRect>()
    private let autoScrollModelsLayoutSubject = PublishSubject<AutoScrollModel>()
    private let autoScrollViewSubject = PublishSubject<AutoScrollModel>()
    // output
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
    let disposeBag = DisposeBag()

    // Initializer
    init(calendarViewModel: CalendarModelType, adMobModel: SetAdMobModelType, fetchTodayDateModel: FetchTodayDateModelType, autoScrollModel: AutoScrollModelType) {

        calendarModel = calendarViewModel
        setAdMobModel = adMobModel
        todayDateModel = fetchTodayDateModel
        autoScroll = autoScrollModel
        // calendarModels function---------------------------------全体データとauth判別の発火
        //        calendarModel.input.bindFetchData()
        calendarModel.input.authState()
        // AdMob---------------------------------------------------AdMobレイアウト用viewWidthSizeの転送
        viewWidthSizeSubject
            .subscribe { [self] size in
                setAdMobModel.setAdMob(viewWidthSize: size.element?.size ?? 0, Self: size.element!.VC)
            }
            .disposed(by: disposeBag)
        // AdMob---------------------------------------------------AdMob本体をviewに通知
        setAdMobModel
            .output
            .SetAdMobModelObservable
            .subscribe { [self] setAdMob in
                setAdMobBannerlRelay.accept(setAdMob)
            }
            .disposed(by: disposeBag)
        // データ----------------------------------------------------取ってきた全部データを選別前に一旦articlesSubjectに入れてる（必要？）
        calendarModel
            .output
            .calendarModelObservable
            .subscribe { [self] data in
                articlesSubject.onNext(data)
            }
            .disposed(by: disposeBag)
        // 匿名認証-----------------------------------------------------発火させた関数の結果をviewに中継してるだけ
        calendarModel
            .output
            ._authStatusObserbable
            .subscribe { [self] auth in
                switch auth {
                case .anonymous:
                    calendarModel.input.bindFetchData()
                    authStateSubject.onNext(auth)
                case .error(let message):
                    print(message)
                    calendarModel.input.bindFetchData() // ネットワークエラーが発生した時に、ローカルのRealmデータを使用してUIを更新
                    calendarModel.input.updateUIFromRealmData() // ネットワークエラーが発生した時に、ローカルのRealmデータを使用してUIを更新⭐️
                default:
                    break
                }
            }
            .disposed(by: disposeBag)

        func showAlert(message: String) {
            // ここに、メッセージを使用してエラーダイアログを表示するコードを書く
        }
        // autoScrollLabelLayout  viewsBounds-------------------------レイアウト用のviewsのBounds通知
        scrollBaseViewBoundsSubject
            .map({ [self] viewsBounds in
                autoScroll
                    .input
                    .autoScrollLabelLayoutArrange(scrollLabel: autoScroll as! AutoScrollModel, scrollBaseViewsBounds: viewsBounds)
            })
            .bind(to: autoScrollModelsLayoutSubject)
            .disposed(by: disposeBag)
        // collectionViewSelectedUrlRelay----------------------------選択indexPathを元に遷移先のURLをviewに通知
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
        // ---------------------------------------------------------------------------------------------------------
        // スクロールラベルの内容の生成
        Observable
            .combineLatest(calendarSelectedDateSubject.asObservable(), showableInfosRelay.asObservable(), autoScrollModelsLayoutSubject.asObservable())
            .map { [self]selectedDate, title, layout  in
                let selected = formatDate(date: selectedDate)
                let scrollWord = "【\(selected)のお得情報】" + title.map { $0.article_title }.joined(separator: "　　　")
                layout.text = scrollWord
                return layout
            }
            .bind(to: autoScrollViewSubject)
            .disposed(by: disposeBag)
        // 読み込み中インジケーター表示用の状態判別
        Observable
            .merge(
                calendarSelectedDateSubject
                    .map { _ in true }
                    .debug("selectDateSubject"),// ビルドデバッグエリア右下フィルター活用
                showableInfosRelay
                    .map { _ in false }
                    .debug("articlesSubject")
            )
            .debug("bind")
            .bind(to: isLoadingSubject)
            .disposed(by: disposeBag)
        // 選択日のコレクションビュー表示用データの選択日付を元に最終絞り込み
        Observable.combineLatest(calendarSelectedDateSubject.asObservable(), articlesSubject.asObservable())
            .debug("原因ちゃうか？")
            .map { [self]  selectDate, data in
                data.filter { checkEnabledDate($0, date: selectDate) }
                    .shuffled()
            }.debug("原因ちゃうか？2")
            .bind(to: showableInfosRelay)
            .disposed(by: disposeBag)
    }
    // MARK: -// Initializerここまで
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
    private func addZeroTapString(date: Date) -> String {// 本当に外に出したいかどうか
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MM-dd-YYYY"
        let tmpDate = Calendar(identifier: .gregorian)
        let tapDayInt = tmpDate.component(.day, from: date)
        let addZeroTapDay = String(format: "%02d", tapDayInt)
        return addZeroTapDay
    }
}
// MARK: - ViewModel Extension
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
extension CalendarViewModel: CalendarViewModelOutput {
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
    var authStateObservable: Observable<AuthStatus> {
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
