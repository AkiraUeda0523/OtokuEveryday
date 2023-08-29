//
//  RecommendationArticleController.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2022/11/24.

import UIKit
import SafariServices
import PinLayout
import Firebase
import FirebaseFirestore
import GoogleMobileAds
import RxSwift
import RxCocoa
import AudioToolbox

fileprivate let GALLERY_SECTION: [Int] = [1,4,7]
fileprivate let TEXT_SECTION: [Int] = [0,3,6]
fileprivate let LIST_SECTION: [Int] = [2,5,8]

class RecommendationArticleController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    let recommendationArticleViewModel: RecommendationArticleViewModelType
    
    required init?(coder: NSCoder) {
        recommendationArticleViewModel = RecommendationArticleViewModel(model: RecommendationArticleModel())
        super.init(coder: coder)
        self.recommendationArticleSetUpLayout()
    }
    private let disposeBag = DisposeBag()
    private var rxRecommendArray = [RecommendModel]()
    private var rxRecomendTitleArray = [RecomendTitleModel]()
    private var RecommendArray1 = [RecommendModel]()
    private var RecommendArray2 = [RecommendModel]()
    private var RecommendArray4 = [RecommendModel]()
    private var RecommendArray5 = [RecommendModel]()
    private var RecommendArray7 = [RecommendModel]()
    private var RecommendArray8 = [RecommendModel]()
    
    private let RecommendDataRelay = BehaviorRelay<[RecommendModel]>(value: [])
    private let RecommendTitleRelay = BehaviorRelay<[RecomendTitleModel]>(value: [])
    
    var RecommendData: Observable<[RecommendModel]> {
        RecommendDataRelay.asObservable()
    }
    var RecommendTitle: Observable<[RecomendTitleModel]> {
        RecommendTitleRelay.asObservable()
    }
    private var adMobBannerView = GADBannerView()
    private let adMobId = ""
    
    @IBOutlet weak var recommendEmptyView: UIView!
    @IBOutlet weak var bannerView: UIView!
    @IBOutlet weak var RecommendView: UIView!
    
    lazy var collectionView: UICollectionView = {
        let collectionView: UICollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: self.makeLayout())
        collectionView.backgroundColor = UIColor.white
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(SmallRecommendCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.register(LargeRecommendCell.self, forCellWithReuseIdentifier: "featured")
        collectionView.register(RecommendTitleText.self, forCellWithReuseIdentifier: "text")
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    let pageControl: UIPageControl = {
        let control = UIPageControl()
        control.currentPageIndicatorTintColor = .black
        control.pageIndicatorTintColor = .lightGray
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recommendationArticleViewModel
            .output
            .RecommendationArticleViewModelObservable
            .subscribe { [self] data in
                RecommendDataRelay.accept(data)
            }
            .disposed(by: disposeBag)
        
        recommendationArticleViewModel
            .output
            .RecommendationArticleViewModelTitleObservable
            .subscribe { [self] title in
                RecommendTitleRelay.accept(title)
            }
            .disposed(by: disposeBag)
        
        bannerView.backgroundColor = .white
        setUpAdmobView()
        
        let collectionViewBackGroundView: UIImageView = {
            let view = UIImageView()
            view.backgroundColor = UIColor.red
            view.image = UIImage(named: "go1")
            view.contentMode = .scaleAspectFill
            return view
        }()
        
        collectionView.register(FooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "Footer")
        
        collectionView.backgroundView?.addSubview(collectionViewBackGroundView)
        
        let backgroundImage = UIImage(named: "back6")!
        collectionView.backgroundColor = UIColor(patternImage: backgroundImage)
        
        self.RecommendView.addSubview(self.collectionView)
        
        NSLayoutConstraint.activate([
            self.collectionView.topAnchor.constraint(equalTo: self.RecommendView.topAnchor),
            self.collectionView.bottomAnchor.constraint(equalTo: self.RecommendView.bottomAnchor),
            self.collectionView.leftAnchor.constraint(equalTo: self.RecommendView.leftAnchor),
            self.collectionView.rightAnchor.constraint(equalTo: self.RecommendView.rightAnchor)
            
        ])
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        recommendationArticleViewModel.input.fetchRecommendDataTitleTriggerObserver.onNext(())
    }
    
    private func setUpAdmobView(){
        adMobBannerView = GADBannerView(adSize:GADAdSizeBanner)
        adMobBannerView.frame.size = CGSize(width:self.view.frame.width, height:adMobBannerView.frame.height)
        adMobBannerView.adUnitID = adMobId
        adMobBannerView.rootViewController = self
        bannerView.addSubview(adMobBannerView)
        adMobBannerView.load(GADRequest())
        self.view.bringSubviewToFront(bannerView)
    }
    func recommendationArticleSetUpLayout(){
        RecommendDataRelay
            .subscribe(onNext: { [weak self]  articles in
                self?.collectionView.isHidden = articles.count == .zero
                self?.rxRecommendArray = articles
                self?.RecommendArray1 = articles.filter{$0.type == 1 }.sorted(by: { $0.month < $1.month })
                self?.RecommendArray2 = articles.filter{$0.type == 2 }.sorted(by: { $0.month < $1.month })
                self?.RecommendArray4 = articles.filter{$0.type == 4 }.sorted(by: { $0.month < $1.month })
                self?.RecommendArray5 = articles.filter{$0.type == 5 }.sorted(by: { $0.month < $1.month })
                self?.RecommendArray7 = articles.filter{$0.type == 7 }.shuffled()
                self?.RecommendArray8 = articles.filter{$0.type == 8 }//.shuffled()
                self?.collectionView.reloadData()
            })
            .disposed(by: disposeBag)
        
        RecommendTitleRelay
            .subscribe(onNext: { title in
                self.rxRecomendTitleArray = title
                self.collectionView.reloadData()
            })
            .disposed(by: disposeBag)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionFooter:
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Footer", for: indexPath) as! FooterView
            if GALLERY_SECTION.contains(indexPath.section) || LIST_SECTION.contains(indexPath.section) {
                footer.pageControl.isHidden = false
                if LIST_SECTION.contains(indexPath.section) {
                    let numberOfItems = self.collectionView(collectionView, numberOfItemsInSection: indexPath.section)
                    footer.pageControl.numberOfPages = Int(ceil(Double(numberOfItems) / 3.0))
                } else {
                    footer.pageControl.numberOfPages = self.collectionView(collectionView, numberOfItemsInSection: indexPath.section)
                }
                let pageWidth = collectionView.bounds.width
                footer.pageControl.currentPage = Int((collectionView.contentOffset.x + pageWidth / 2) / pageWidth)
            } else {
                footer.pageControl.isHidden = true
            }
            return footer
        default:
            fatalError("Invalid element type: \(kind)")
        }
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if GALLERY_SECTION.contains(section) || LIST_SECTION.contains(section) {
            return CGSize(width: collectionView.bounds.size.width, height: 10)
        } else {
            return CGSize.zero
        }
    }
    
    func makeLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (section: Int, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            if GALLERY_SECTION.contains(section) {
                
                
                let sectionLayout = LayoutBuilder.rectangleHorizonContinuousWithFooterSection(collectionViewBounds: self.collectionView.bounds)
                sectionLayout.visibleItemsInvalidationHandler = { [weak self] visibleItems, offset, _ in
                    guard let self = self else { return }
                    guard !visibleItems.isEmpty else { return }
                    let centerOffset = offset.x + self.collectionView.bounds.width / 2
                    var smallestDistance = CGFloat.infinity
                    var closestIndex = 0
                    for item in visibleItems {
                        let distance = abs(item.frame.midX - centerOffset)
                        
                        if distance < smallestDistance {
                            smallestDistance = distance
                            closestIndex = item.indexPath.item
                        }
                    }
                    DispatchQueue.main.async {
                        let footer = self.collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter, at: IndexPath(item: 0, section: section)) as? FooterView
                        footer?.pageControl.currentPage = closestIndex
                    }
                }
                return sectionLayout
            }
            else if TEXT_SECTION.contains(section) {
                return LayoutBuilder.buildTextSectionLayout()
            } else if LIST_SECTION.contains(section) {
                let sectionLayout = LayoutBuilder.buildHorizontalTableSectionLayout(collectionViewBounds: self.collectionView.bounds)
                sectionLayout.visibleItemsInvalidationHandler = { [weak self] visibleItems, offset, _ in
                    guard let self = self else { return }
                    guard !visibleItems.isEmpty else { return }
                    let centerOffset = offset.x + self.collectionView.bounds.width / 2
                    var smallestDistance = CGFloat.infinity
                    var closestIndex = 0
                    for item in visibleItems {
                        let distance = abs(item.frame.midX - centerOffset)
                        if distance < smallestDistance {
                            smallestDistance = distance
                            closestIndex = item.indexPath.item
                        }
                    }
                    let closestGroupIndex = closestIndex / 3
                    DispatchQueue.main.async {
                        let footer = self.collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter, at: IndexPath(item: 0, section: section)) as? FooterView
                        footer?.pageControl.currentPage = closestGroupIndex
                    }
                }
                return sectionLayout
            }
            return LayoutBuilder.buildHorizontalTableSectionLayout(collectionViewBounds: self.collectionView.bounds)
        }
        return layout
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 9
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let urlArrays = [
            1: RecommendArray1,
            2: RecommendArray2,
            4: RecommendArray4,
            5: RecommendArray5,
            7: RecommendArray7,
            8: RecommendArray8
        ]
        return urlArrays[section]?.count ?? 1
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if GALLERY_SECTION.contains(indexPath.section) {
            return CellBuilder.getFeaturedCell(collectionView: collectionView, indexPath: indexPath,RecommendArray1:self.RecommendArray1,RecommendArray4:self.RecommendArray4,RecommendArray7:self.RecommendArray7)
        }
        if TEXT_SECTION.contains(indexPath.section) {
            return CellBuilder.getTextCell(collectionView: collectionView, indexPath: indexPath, title:self.rxRecomendTitleArray)
            
        }
        if LIST_SECTION.contains(indexPath.section) {
            return CellBuilder.getListCell(collectionView: collectionView, indexPath: indexPath,RecommendArray2:self.RecommendArray2,RecommendArray5:self.RecommendArray5,RecommendArray8:self.RecommendArray8)
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        AudioServicesPlaySystemSound(1519)
        let urlArrays = [
            1: RecommendArray1,
            2: RecommendArray2,
            4: RecommendArray4,
            5: RecommendArray5,
            7: RecommendArray7,
            8: RecommendArray8
        ]
        guard let array = urlArrays[indexPath.section], let url = URL(string: array[indexPath.row].blog_web_url) else {
            let defaultUrl = URL(string: RecommendArray1[indexPath.row].blog_web_url)!
            presentSafariViewController(url: defaultUrl)
            return
        }
        presentSafariViewController(url: url)
    }
    private func presentSafariViewController(url: URL) {
        let safariView = SFSafariViewController(url: url)
        present(safariView, animated: true)
    }
}
extension UIColor {
    static func rgb(red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor{
        return self.init(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
    }
}
class FooterView: UICollectionReusableView {
    let pageControl: UIPageControl = {
        let control = UIPageControl()
        control.currentPageIndicatorTintColor = .systemRed.withAlphaComponent(0.8)
        control.pageIndicatorTintColor = .darkGray.withAlphaComponent(0.8)
        control.layer.apply{
            $0.shadowOpacity = 0.3
            $0.shadowRadius = 2
            $0.shadowColor = UIColor.black.cgColor
            $0.shadowOffset = CGSize(width: 3, height: 3)
        }
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(pageControl)
        NSLayoutConstraint.activate([
            pageControl.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            pageControl.topAnchor.constraint(equalTo: self.topAnchor)
        ])
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
