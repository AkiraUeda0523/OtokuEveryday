//
//  RecommendationArticleViewModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2023/01/10.
//
import Foundation
import RxSwift
import RxRelay
import MapKit
import GoogleMobileAds
import FirebaseFirestore
// MARK: - Protocols
protocol RecommendationArticleViewModelInput {
    var viewWidthSizeObserver: AnyObserver<SetAdMobModelData> { get }
    func fetchData()
    var itemSelected: AnyObserver<IndexPath> { get }
    var largeSectionisScrollingObserver: AnyObserver<Void> { get }
    var smallSectionScrollingObserver: AnyObserver<Void> { get }
    var pageControlIsChangingObserver: AnyObserver<Bool> { get } // ページコントロール変更通知用
    var scrollCompletionObserver: AnyObserver<Void> { get }
    func calculateTargetIndexPath(sectionMappings: [SectionNumber: SectionType], sectionIndex: Int, targetPage: Int) -> IndexPath
    func isValidIndexPath(_ indexPath: IndexPath, for collectionView: UICollectionView, inSection sectionIndex: Int) -> Bool
    func waitForScrollCompletionOrTimeout() async throws
}
protocol RecommendationArticleViewModelOutput {
    var RecommendationArticleViewModelObservable:Observable<[Int: [RecommendModel]]> { get }
    var setAdMobBannerObservable: Observable<GADBannerView> { get }
    var urlToOpen: Observable<URL> { get }
    var largeSectionisScrollingObservable: Observable<Void> { get }
    var smallSectionisScrollingObservable: Observable<Void> { get }
    var pageControlIsChangingObservable: Observable<Bool> { get }
    var scrollCompletionObservable:Observable<Void> {get}
}
protocol RecommendationArticleViewModelType {
    var output: RecommendationArticleViewModelOutput { get }
    var input: RecommendationArticleViewModelInput { get }
}
// MARK: - Main Class
final class  RecommendationArticleViewModel{
    let disposeBag = DisposeBag()
    let RecommendationArticleViewModelRelay = BehaviorRelay<[Int: [RecommendModel]]>(value: [:])
    internal let viewWidthSizeSubject = PublishSubject<SetAdMobModelData>()
    private let setAdMobBannerlRelay = PublishRelay<GADBannerView>()
    let recommendationArticleModel: RecommendationArticleModelType
    let setAdMobModel: SetAdMobModelType
    let urlToOpenSubject = PublishSubject<URL>()
    var itemSelectedSubject = PublishSubject<IndexPath>()
    var fetchRecommendDataTitleTrigger = PublishSubject<Void>()
    // スクロール状態を通知するSubject
    var largeSectionscrollingSubject = PublishSubject<Void>()
    var smallSectionscrollingSubject = PublishSubject<Void>()
    // ページコントロール変更通知用のSubject
    private let pageControlIsChangingSubject = BehaviorSubject<Bool>(value: false)
    private let scrollCompletionSubject = PublishSubject<Void>()
    
    init(model: RecommendationArticleModelType,adMobModel: SetAdMobModelType) {
        recommendationArticleModel = model
        setAdMobModel = adMobModel
        // MARK: -
        //         adMobバナー作成の為にVCからWidthSizeの通知を受け取る
        viewWidthSizeSubject
            .subscribe {  size in
                adMobModel
                    .setAdMob(bannerWidthSize: size.element?.bannerWidth ?? 0,bannerHeight: size.element?.bannerHeight ?? 0, viewController: size.element!.VC)
            }
            .disposed(by: disposeBag)
        // 出来上がったAdMobバナーの設定情報
        self.setAdMobModel
            .output
            .SetAdMobModelObservable
            .subscribe { [self] (setAdMob: AdBannerView) in
                setAdMobBannerlRelay.accept(setAdMob as! GADBannerView)
            }
            .disposed(by: disposeBag)
        // MARK: -
        Observable.combineLatest(
            recommendationArticleModel.output.recommendDataObservable,
            recommendationArticleModel.output.recommendTitleObservable
        )
        .filter { data, title in
            // dataとtitleのどちらも空でない（空文字でもない）場合のみ通過させる
            return !data.isEmpty && !title.isEmpty && !title.contains(where: { $0.article_title.isEmpty })
        }
        .map { data, title in
            // dataとtitleを結合し、一つのRecommendModelの配列にします。
            let combinedData = data + title
            // 結合されたデータを加工して、typeに基づいてグループ化し、monthでソートします。
            return self.organizeData(recommendModels: combinedData)
        }
        .subscribe(onNext: { organizedData in
            // 加工されたデータをRelayを通じて他の部分に通知します。
            self.RecommendationArticleViewModelRelay.accept(organizedData)
        })
        .disposed(by: disposeBag)
        // MARK: -
        fetchRecommendDataTitleTrigger
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.recommendationArticleModel.input.fetchRecommendData()
                self.recommendationArticleModel.input.fetchRecommendTitle()
            })
            .disposed(by: disposeBag)
        // MARK: -
        itemSelectedSubject
            .flatMap { [unowned self] indexPath -> Observable<URL> in
                // RecommendationArticleViewModelRelayから最新のデータを取得
                let data = self.RecommendationArticleViewModelRelay.value
                // 選択されたindexPathに基づいて適切なRecommendModelを取得
                guard let modelsInSection = data[indexPath.section],
                      indexPath.row < modelsInSection.count,
                      let url = URL(string: modelsInSection[indexPath.row].blog_web_url) else {
                    // 条件に合致するURLが見つからない場合は空のObservableを返す
                    return .empty()
                }
                // 見つかったURLを含むObservableを返す
                return .just(url)
            }
            .subscribe(onNext: { url in
                self.urlToOpenSubject.onNext(url)
            })
            .disposed(by: disposeBag)
    }
    // MARK: -
    func organizeData(recommendModels: [RecommendModel]) -> [Int: [RecommendModel]] {
        // `type`に基づいてデータをグループ化し、`month`でソート
        return Dictionary(grouping: recommendModels) { $0.type }
            .mapValues { models in
                models.sorted(by: { $0.month < $1.month })
            }
    }
}
// MARK: - Input
extension RecommendationArticleViewModel: RecommendationArticleViewModelInput {
    func waitForScrollCompletionOrTimeout() async throws {//全て別スレッド
        // ThrowingTaskGroupで例外処理を管理
        try await withThrowingTaskGroup(of: Void.self) { group in
            //            最初のタスクが完了した後、残りのタスクをキャンセルして次の処理へ
            defer {
                print("タスク４バックグラウンド（タスク終了でキャンセル）")
                group.cancelAll()
            }
            // タスク1: scrollCompletionObservableからの通知を待機
            group.addTask {
                for try await _ in self.scrollCompletionObservable
                    .take(1)
                    .asSingle()
                    .asObservable()
                    .asAsyncStream() {
                    print("タスク３バックグラウンド（スクロール完了）")
                    return
                }
            }
            //             タスク2: タイムアウトまで1.2秒待機
            group.addTask {
                try await Task.sleep(nanoseconds: 1_200_000_000)//いいね
                print("タスク３バックグラウンド（1.2秒タイムアップ）")
                throw TimeoutError(message: "Scroll completion signal not received within 1.2 seconds")
            }
            // 最初に完了したタスクの結果を待機
            // ここで完了したタスクの成功または失敗を待ち、次のステップへ進む
            print("タスク２バックグラウンド（最初のタスクが完了するのを待機中）")
            try await group.next()
        }
    }
    
    func isValidIndexPath(_ indexPath: IndexPath, for collectionView: UICollectionView, inSection sectionIndex: Int) -> Bool {
        let numberOfItems = collectionView.numberOfItems(inSection: sectionIndex)
        return indexPath.item < numberOfItems
    }
    
    func calculateTargetIndexPath(sectionMappings: [SectionNumber : SectionType], sectionIndex: Int, targetPage: Int) -> IndexPath {
        let isSmallSection = sectionMappings[SectionNumber(sectionIndex)] == .small
        let itemIndex = isSmallSection ? targetPage * 3 : targetPage
        return IndexPath(item: itemIndex, section: sectionIndex)
    }
    // MARK: -
    var scrollCompletionObserver: RxSwift.AnyObserver<Void> {
        scrollCompletionSubject.asObserver()
    }
    var pageControlIsChangingObserver: AnyObserver<Bool> {
        return pageControlIsChangingSubject.asObserver()
    }
    var largeSectionisScrollingObserver: RxSwift.AnyObserver<Void> {
        return largeSectionscrollingSubject.asObserver()
    }
    var smallSectionScrollingObserver: RxSwift.AnyObserver<Void> {
        return smallSectionscrollingSubject.asObserver()
    }
    var itemSelected: AnyObserver<IndexPath> {
        return itemSelectedSubject.asObserver()
    }
    var viewWidthSizeObserver: AnyObserver<SetAdMobModelData> {
        return viewWidthSizeSubject.asObserver()
    }
    // ViewControllerから呼び出されるデータ取得開始メソッド
    func fetchData()  {
        fetchRecommendDataTitleTrigger.onNext(())
    }
}
// MARK: - Output
extension RecommendationArticleViewModel: RecommendationArticleViewModelOutput {
    var scrollCompletionObservable: RxSwift.Observable<Void> {
        scrollCompletionSubject.asObservable()
    }
    var largeSectionisScrollingObservable: RxSwift.Observable<Void> {
        return largeSectionscrollingSubject.asObservable()
    }
    var smallSectionisScrollingObservable: RxSwift.Observable<Void> {
        return smallSectionscrollingSubject.asObservable()
    }
    var urlToOpen: Observable<URL> {
        return urlToOpenSubject.asObservable()
    }
    var RecommendationArticleViewModelObservable: Observable<[Int: [RecommendModel]]> {
        RecommendationArticleViewModelRelay.asObservable()
    }
    var setAdMobBannerObservable: Observable<GADBannerView> {
        return setAdMobBannerlRelay.asObservable()
    }
    var pageControlIsChangingObservable: Observable<Bool> {
        return pageControlIsChangingSubject.asObservable()
    }
}
// MARK: - Additional Extensions
extension RecommendationArticleViewModel: RecommendationArticleViewModelType {
    var output: RecommendationArticleViewModelOutput { return self }
    var input: RecommendationArticleViewModelInput { return self }
}
// MARK: -
extension ObservableType {
    func asAsyncStream() -> AsyncThrowingStream<Element, Error> {
        AsyncThrowingStream { continuation in
            let disposable = self.subscribe(
                onNext: { continuation.yield($0) },
                onError: { continuation.finish(throwing: $0) },
                onCompleted: { continuation.finish() }
            )
            continuation.onTermination = { @Sendable _ in
                disposable.dispose()
            }
        }
    }
}
// MARK: -
struct TimeoutError: Error {
    let message: String
}
