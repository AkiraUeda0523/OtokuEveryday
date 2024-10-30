////
////  RecommendationArticleController.swift
////  RedMoon2021
////
////  Created by 上田晃 on 2022/11/24.
import UIKit
import SafariServices
import GoogleMobileAds
import RxSwift
import RxCocoa
import AudioToolbox
import RxDataSources
// セクション番号用の型エイリアス
typealias SectionNumber = Int

enum SectionType {
    case title, large, small
}
class RecommendationArticleController: UIViewController{
    // MARK: -
    // 型エイリアスを使用してsectionMappingsを定義
    private let sectionMappings: [SectionNumber: SectionType] = [
        0: .title, 1: .large, 2: .small,
        3: .title, 4: .large, 5: .small,
        6: .title, 7: .large, 8: .small
    ]
    // MARK: -
    private var disposeBag = DisposeBag()
    private let adMobBannerView = GADBannerView()
    private var sectionPageIndices: [Int: Int] = [:]
    // ViewModelのインスタンス
    private let recommendationArticleViewModel: RecommendationArticleViewModelType
    var         scrollPageUpdater: PageUpdater
    @IBOutlet weak var recommendEmptyView: UIView!
    @IBOutlet weak var bannerView: UIView!
    @IBOutlet weak var RecommendView: UIView!
    @IBOutlet weak var baseViewHeightConstraint: NSLayoutConstraint!
    private var admobBannerView: GADBannerView?
    // MARK: -init
    required init?(coder: NSCoder) {
        recommendationArticleViewModel = RecommendationArticleViewModel(model: RecommendationArticleModel(), adMobModel: SetAdMobModel())
        scrollPageUpdater = ScrollPageUpdater()
        super.init(coder: coder)
    }
    // MARK: -collectionView
    private lazy var collectionView: UICollectionView = {
        let layout = makeLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
            .configured(
                withLayout: layout
            )
        // 背景画像を設定
        let backgroundImage = UIImage(named: "back6")!
        collectionView.backgroundColor = UIColor(patternImage: backgroundImage)
        return collectionView
    }()
    // MARK: -dataSource ⚠️Lazyプロパティの重要性、初期化は同期的に行われ、初期化が完了するまで次の処理に進みません。
    private lazy var dataSource: RxCollectionViewSectionedAnimatedDataSource<SectionModel> = {
        RxCollectionViewSectionedAnimatedDataSource<SectionModel>(
            configureCell: { [weak self] dataSource, collectionView, indexPath, item in
                guard let self = self else { return UICollectionViewCell() }
                let sectionType = dataSource.sectionModels[indexPath.section].sectionType
                switch sectionType {
                case .title:
                    return CellBuilder.getTitleCell(collectionView: collectionView, indexPath: indexPath, recommendModel: item)
                case .large:
                    return CellBuilder.getLargeCell(collectionView: collectionView, indexPath: indexPath, recommendModel: item)
                case .small:
                    return CellBuilder.getSmallCell(collectionView: collectionView, indexPath: indexPath, recommendModel: item)
                }
            },
            configureSupplementaryView: { [weak self] dataSource, collectionView, kind, indexPath in
                return self?.configureFooter2(for: collectionView, kind: kind, indexPath: indexPath) ?? UICollectionReusableView()//最終2にする
            }
        )
    }()
    //    // MARK: -viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        bannerView.backgroundColor = .white
        RecommendView.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: RecommendView.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: RecommendView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: RecommendView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: RecommendView.trailingAnchor)
        ])
        Task {
            do {
                try await fetchDataAndBind()
            } catch {
                handleError(error)
            }
        }
        self.handleItemSelectedActions()//viewWillAppearより移動
    }
    // MARK: -
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
    // MARK: -データ関係
    private func fetchDataAndBind() async throws {
        // データの取得を待機
        recommendationArticleViewModel.input.fetchData()
        do {
            // ObservableをSingleに変換し、値を取得
            let data: [Int: [RecommendModel]] = try await recommendationArticleViewModel.output.RecommendationArticleViewModelObservable
                .filter { value in
                    return !value.isEmpty
                }
                .take(1)
                .asSingle()
                .catch { error in
                    return .never()
                }
                .value
            bindDataToCollectionView(data: data)
        } catch {
            print("Error fetching data: \(error)")
        }
    }
    
    private func handleError(_ error: Error) {
        print("Error fetching data: \(error)")
    }
    
    private func bindDataToCollectionView(data: [Int: [RecommendModel]]) {
        let sectionModels = sectionMappings.compactMap { sectionNumber, sectionType -> SectionModel? in
            guard let items = data[sectionNumber] else { return nil }
            return SectionModel(sectionNumber: sectionNumber, sectionType: sectionType, items: items)
        }.sorted(by: { $0.sectionNumber < $1.sectionNumber })
        let observable = Observable.just(sectionModels)
        observable
            .bind(to: collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
    
    private func handleItemSelectedActions() {
        collectionView.rx.itemSelected
            .subscribe(onNext: { [unowned self] indexPath in
                self.collectionView.deselectItem(at: indexPath, animated: true)
                AudioServicesPlaySystemSound(1519)  // 音を再生
                self.recommendationArticleViewModel.input.itemSelected.onNext(indexPath)
            })
            .disposed(by: disposeBag)
        
        recommendationArticleViewModel
            .output
            .urlToOpen
            .subscribe(onNext: { [unowned self] url in
                let safariView = SFSafariViewController(url: url)
                self.present(safariView, animated: true)
            })
            .disposed(by: disposeBag)
    }
    // MARK: - UICollectionViewのセクションフッター設定　フッター移動？
    
    // フッターView初期化メソッド
    private func configureFooter2(for collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionFooter else {
            return UICollectionReusableView()
        }
        guard let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Footer", for: indexPath) as? FooterView else {
            fatalError("Cannot create footer view")
        }
        let sectionModel = dataSource.sectionModels[indexPath.section]//空があり得る
        // FooterViewの設定
        footerView.collectionView = collectionView
        footerView.sectionIndex = indexPath.section
        footerView.sectionMappings = sectionMappings
        //⚠️追加
        footerView.bindViewModel(recommendationArticleViewModel)
        // PageControlの設定
        configurePageControl2(for: footerView, at: indexPath, in: collectionView, with: sectionModel)
        return footerView
    }
    
    private func configurePageControl2(for footerView: FooterView, at indexPath: IndexPath, in collectionView: UICollectionView, with sectionModel: SectionModel) {
        footerView.pageControl.isHidden = sectionModel.sectionType != .large && sectionModel.sectionType != .small
        if sectionModel.sectionType == .small {
            footerView.pageControl.numberOfPages = Int(ceil(Double(sectionModel.items.count) / 3.0))
        } else {
            footerView.pageControl.numberOfPages = sectionModel.items.count
        }
        //⚠️追加
        let currentPageIndex = sectionPageIndices[indexPath.section] ?? 0
        footerView.pageControl.currentPage = currentPageIndex
    }
    // PageControlを更新するメソッド
    private func updatePageControl(forSection sectionIndex: Int, pageIndex: Int) {
        let footerIndexPath = IndexPath(item: 0, section: sectionIndex)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let footer = self.collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter, at: footerIndexPath) as? FooterView {
                footer.updatePageIndex(pageIndex)
                self.sectionPageIndices[sectionIndex] = pageIndex
            } else {
            }
        }
    }
    // MARK: -レイアウトまとめ
    
    private func makeLayout() -> UICollectionViewLayout {
        let LayoutBuilder = LayoutBuilder()
        let layout = UICollectionViewCompositionalLayout { [weak self] (sectionIndex, environment) -> NSCollectionLayoutSection? in
            guard let self = self else { return nil }
            // sectionMappingsはセクションインデックスに基づいてセクションタイプを返す
            guard let sectionType = sectionMappings[sectionIndex] else {
                // 未定義のセクションタイプの場合はデフォルトレイアウトを返す
                return self.scrollPageUpdater.DefaultSectionLayout(for: sectionIndex, recommendViewBounds: self.RecommendView.bounds)
            }
            switch sectionType {
            case .title:
                return LayoutBuilder.buildTextSectionLayout(recommendViewBounds: self.RecommendView.bounds)
            case .large:
                return self.scrollPageUpdater.LargeSectionPageUpdater(for: sectionIndex, recommendationArticleViewModel: recommendationArticleViewModel, recommendViewBounds: self.RecommendView.bounds) { pageIndex in
                    self.updatePageControl(forSection: sectionIndex, pageIndex: pageIndex)
                }
            case .small:
                return self.scrollPageUpdater.SmallSectionPageUpdater(for: sectionIndex, recommendationArticleViewModel: recommendationArticleViewModel, recommendViewBounds: self.RecommendView.bounds) { pageIndex in
                    self.updatePageControl(forSection: sectionIndex, pageIndex: pageIndex)
                }
            }
        }
        return layout
    }
    // MARK: -AdMob設定
    private func setAdMobBanner() {
        // バナーがすでに存在する場合は何もしない
        guard admobBannerView == nil else {
            return
        }
        recommendationArticleViewModel
            .output
            .setAdMobBannerObservable
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] setAdMob in
                guard let self = self else { return }
                // AdMobバナーの参照を保持
                self.admobBannerView = setAdMob
                // 広告バナーを既存のビューから削除し、再追加
                self.bannerView.subviews.forEach { $0.removeFromSuperview() }
                self.baseViewHeightConstraint.constant = setAdMob.adSize.size.height
                // 新しい広告バナーを追加
                self.bannerView.addSubview(setAdMob)
                
                setAdMob.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    setAdMob.leadingAnchor.constraint(equalTo: self.bannerView.leadingAnchor),
                    setAdMob.trailingAnchor.constraint(equalTo: self.bannerView.trailingAnchor),
                    setAdMob.topAnchor.constraint(equalTo: self.bannerView.topAnchor),
                    setAdMob.heightAnchor.constraint(equalToConstant: setAdMob.adSize.size.height)
                ])
                // レイアウトの更新
                self.view.layoutIfNeeded()
            })
            .disposed(by: disposeBag)
        
        // バナーサイズとVC情報をViewModelに通知
        recommendationArticleViewModel
            .input
            .viewWidthSizeObserver
            .onNext(SetAdMobModelData(bannerWidth: self.view.frame.width, bannerHeight: self.bannerView.frame.height, VC: self))
    }
    
    private func removeAdMobBanner() {
        // バナーが存在すれば削除
        admobBannerView?.removeFromSuperview()
        admobBannerView = nil
    }
}
// MARK: -extension UIColor
extension UIColor {
    static func rgb(red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        return self.init(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
    }
}
// MARK: -extension UICollectionView
extension UICollectionView {
    @discardableResult
    func configured(
        withLayout layout: UICollectionViewLayout
        ,isPagingEnabled: Bool = true
    ) -> UICollectionView {
        self.collectionViewLayout = layout
        self.isPagingEnabled = isPagingEnabled
        self.translatesAutoresizingMaskIntoConstraints = false
        // セル、ヘッダー、フッターの登録はregisterCellsメソッドで実施
        self.registerCells()
        return self
    }
    private func registerCells() {
        self.register(SmallRecommendCell.self, forCellWithReuseIdentifier: "cell")
        self.register(LargeRecommendCell.self, forCellWithReuseIdentifier: "featured")
        self.register(RecommendTitleText.self, forCellWithReuseIdentifier: "text")
        self.register(FooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "Footer")
    }
}
// RecommendModelがIdentifiableTypeとEquatableに準拠していることを確認
extension RecommendModel: IdentifiableType, Equatable {
    var identity: Int {
        return self.hashValue
    }
    static func ==(lhs: RecommendModel, rhs: RecommendModel) -> Bool {
        return lhs.identity == rhs.identity
    }
}
struct SectionModel {
    var sectionNumber: Int//identityじゃ？
    var sectionType: SectionType
    var items: [Item]
}
extension SectionModel: AnimatableSectionModelType {
    typealias Item = RecommendModel
    typealias Identity = Int
    var identity: Int {
        return sectionNumber
    }
    init(original: SectionModel, items: [Item]) {
        self = original
        self.items = items
    }
}
// MARK: -アンサー
//・dataSource.sectionModels[indexPath.section].items
//・configureSupplementaryViewが呼ばれるのは、dataSourceが初期化され、データがバインドされた後（完了とは言っていない。これ大事）
//・初期化は同期的に行われ、初期化が完了するまで次の処理に進みません。


//比較用旧
//private func configureFooter(for collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView {
//    guard kind == UICollectionView.elementKindSectionFooter else {
//        return UICollectionReusableView()
//    }
//    guard let footerView = collectionView.dequeueReusableSupplementaryView(
//        ofKind: kind,
//        withReuseIdentifier: "Footer",
//        for: indexPath
//    ) as? FooterView else {
//        fatalError("Cannot create footer view")
//    }
//    // FooterViewの設定
//    footerView.collectionView = collectionView
//    footerView.sectionIndex = indexPath.section
//    footerView.sectionMappings = sectionMappings
//    // viewModelをフッターにセット
//    footerView.bindViewModel(recommendationArticleViewModel) // ViewModelをフッターにバインド        // PageControlの設定
//    configurePageControl(for: footerView, at: indexPath, in: collectionView)
////                footerView.updatePageIndex(currentPageIndex)⚠️要らんの？？？？
//    return footerView
//}
//// PageControlを設定するメソッド
//private func configurePageControl(for footerView: FooterView, at indexPath: IndexPath, in collectionView: UICollectionView) {
//    guard let sectionType = sectionMappings[indexPath.section] else {
//        footerView.pageControl.isHidden = true
//        return
//    }
//    footerView.pageControl.isHidden = sectionType != .large && sectionType != .small
//    if sectionType == .small {
//        let numberOfItems = collectionView.numberOfItems(inSection: indexPath.section)
//        footerView.pageControl.numberOfPages = Int(ceil(Double(numberOfItems) / 3.0))
//    } else {
//        footerView.pageControl.numberOfPages = collectionView.numberOfItems(inSection: indexPath.section)
//    }
//
//    let currentPageIndex = sectionPageIndices[indexPath.section] ?? 0
//    footerView.pageControl.currentPage = currentPageIndex
//    //           footerView.updatePageIndex(currentPageIndex)⚠️要らんの？？？？
//}
