import UIKit
import RxSwift
import AudioToolbox

class FooterView: UICollectionReusableView {
    var sectionMappings: [SectionNumber: SectionType]?
    weak var collectionView: UICollectionView?
    var sectionIndex: Int?
    private var disposeBag = DisposeBag()
    private var viewModel: RecommendationArticleViewModelType?
    var currentPage: Int = 0 {
        didSet {
            pageControl.currentPage = currentPage
        }
    }
    
    let pageControl: UIPageControl = {
        let control = UIPageControl()
        control.currentPageIndicatorTintColor = .systemRed.withAlphaComponent(0.8)
        control.pageIndicatorTintColor = .darkGray.withAlphaComponent(0.8)
        control.layer.shadowOpacity = 0.3
        control.layer.shadowRadius = 2
        control.layer.shadowColor = UIColor.black.cgColor
        control.layer.shadowOffset = CGSize(width: 3, height: 3)
        control.translatesAutoresizingMaskIntoConstraints = false
        control.isUserInteractionEnabled = true
        return control
    }()
    
    // 新しい Computed Property
    private var pageControlContext: (collectionView: UICollectionView, sectionIndex: Int, sectionMappings: [SectionNumber: SectionType], viewModel: RecommendationArticleViewModelType)? {
        guard let collectionView = collectionView,
              let sectionIndex = sectionIndex,
              let sectionMappings = sectionMappings,
              let viewModel = viewModel else { return nil }
        return (collectionView, sectionIndex, sectionMappings, viewModel)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    func updatePageIndex(_ index: Int) {
        if currentPage != index {
            currentPage = index
            pageControl.currentPage = index
            AudioServicesPlaySystemSound(1519)
        }
    }
    
    private func setupUI() {
        addSubview(pageControl)
        NSLayoutConstraint.activate([
            pageControl.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            pageControl.topAnchor.constraint(equalTo: self.topAnchor)
        ])
        pageControl.addTarget(self, action: #selector(pageControlValueChanged(sender:)), for: .valueChanged)
    }
    
    func bindViewModel(_ viewModel: RecommendationArticleViewModelType) {
        self.viewModel = viewModel
        //インスタンスの独立性によりmerge
        Observable.merge(
            viewModel.output.largeSectionisScrollingObservable,
            viewModel.output.smallSectionisScrollingObservable
        )
        .withLatestFrom(viewModel.output.pageControlIsChangingObservable)
        .filter { $0 }
        .subscribe(onNext: { _ in
            viewModel.input.scrollCompletionObserver.onNext(())
        })
        .disposed(by: disposeBag)
    }
    // 二つのタイムアウトパターン・スクロール中にしたスクロール（ビジブル自体が吹き飛ぶこの場合タイムアウト必須）・ページスクロールから指スクロールへ（この場合タイムアウトが危ない、スクロール中に戻る）
    @objc func pageControlValueChanged(sender: UIPageControl) {
        guard let context = pageControlContext else {
            print("Required context is not available")
            return
        }//⚠️すごい気になる、⚠️後ワンサイクル遅れるの件
        let (collectionView, sectionIndex, sectionMappings, viewModel) = context
        // メインスレッドで同期的に行う部分
        //        sender.isUserInteractionEnabled = false
        superview?.isUserInteractionEnabled = false
        collectionView.isPagingEnabled = false//やっぱ消したら吹っ飛ぶわ
        viewModel.input.pageControlIsChangingObserver.onNext(true)
        
        let targetIndexPath = viewModel.input.calculateTargetIndexPath(sectionMappings: sectionMappings, sectionIndex: sectionIndex, targetPage: sender.currentPage)
        guard viewModel.input.isValidIndexPath(targetIndexPath, for: collectionView, inSection: sectionIndex) else {
            return
        }
        collectionView.scrollToItem(at: targetIndexPath, at: .centeredHorizontally, animated: true)
        print("タスク１メインスレッド（同期タスクscrollToItem迄）")
        
        Task {
            do {
                defer {
                    viewModel.input.pageControlIsChangingObserver.onNext(false)
                    collectionView.isPagingEnabled = true
                    superview?.isUserInteractionEnabled = true
                    //                    sender.isUserInteractionEnabled = true
                    print("タスク５メインスレッド　プロパティ戻し")
                    
                }
                try await viewModel.input.waitForScrollCompletionOrTimeout()//非同期　別スレッド
            }
            catch {
                print("タスク６メインスレッド　: \(error)")
            }
        }
    }
}

//プロぱ戻す途中でタイムアウト飛び込んできた
//タイムアウトープロぱーエラーープロぱ（バグ戻り確認）


//この場合、各UIPageControlはそれぞれ別のフッターインスタンスに属しているので、独立した存在です。したがって、片方のUIPageControlを有効または無効にしても、もう片方には直接影響を与えません。それぞれのUIPageControlインスタンスは、対応するフッターインスタンス内のロジックに基づいて独立した状態（有効・無効）を持つことができます。
//
//一方、isPagingEnabledプロパティを設定しているUICollectionViewは共有されているため、このプロパティを変更すると、画面全体のスクロール動作が影響を受けることになります。これにより、両方のフッターに影響が及ぶ点に注意が必要です。
