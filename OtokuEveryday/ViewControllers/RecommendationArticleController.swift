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
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.recommendationArticleSetUpLayout()
        fetchRecommendData()
        fetchRecommendTitle()
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
    
    var RecommendDat: Observable<[RecommendModel]> {
        RecommendDataRelay.asObservable()
    }
    var RecommendTitle: Observable<[RecomendTitleModel]> {
        RecommendTitleRelay.asObservable()
    }
    private var adMobBannerView = GADBannerView()
    private let adMobId = "xxxxxxxxxxxxxxxxxxxxxxxxx"
    var recommendTitleBox:[RecomendTitleModel] = []
    var recommendBox:[RecommendModel] = []
    
    struct  RecommendModel:Hashable{
        var article_title:String
        var article_sub_title:String
        var blog_web_url:String
        var collectionView_image_url:String
        var type:Int//intへ変更⚠️
        var month:Int//intへ変更⚠️
        var name:String
    }
    
    struct RecomendTitleModel:Hashable{
        var title:String
        var titleType:Int
    }
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.bannerView.backgroundColor = .clear
        setUpAdmobView()
        fetchRecommendData()
        fetchRecommendTitle()
        
        var collectionViewBackGroundView: UIImageView = {
            let view = UIImageView()
            view.backgroundColor = UIColor.red
            view.image = UIImage(named: "go1")
            view.contentMode = .scaleAspectFill
            return view
        }()
        
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
    
    func fetchRecommendData(){
        
        Firestore.firestore().collection("RecommendationArticle").addSnapshotListener { snapShot, error in
            self.recommendBox = []
            if let snapShotDoc = snapShot?.documents{
                for doc in snapShotDoc{
                    let data = doc.data()
                    if let articleTitle = data["article_title"], let blogWebUrl = data["blog_web_url"] ,
                       let collectionViewImageUrl = data["collectionView_image_url"] ,
                       let type = data["type"] ,
                       let month = data["month"],
                       let name = data["name"]{
                        let articleSubTitle = data["article_sub_title"] as? String
                        let recommenModel = RecommendModel(article_title: articleTitle as! String,article_sub_title: articleSubTitle ?? "", blog_web_url: blogWebUrl as! String, collectionView_image_url:collectionViewImageUrl as! String , type: type as? Int ?? 0, month:month as? Int ?? 0 ,name: name as! String)
                        self.recommendBox.append(recommenModel)
                    }
                }
                self.RecommendDataRelay.accept(self.recommendBox)
                let select = self.recommendBox.filter {$0.type == 1}
            }
        }
    }
    
    func fetchRecommendTitle(){
        
        Firestore.firestore().collection("RecommendationArticleTitle").addSnapshotListener { snapShot, error in
            self.recommendTitleBox = []
            if let snapShotDoc = snapShot?.documents{
                for doc in snapShotDoc{
                    let data = doc.data()
                    if let title = data["title"],
                       let titleType = data["titleType"]
                    {
                        let recommenTitleModel = RecomendTitleModel(title: title as! String, titleType: titleType as! Int)
                        self.recommendTitleBox.append(recommenTitleModel)
                    }
                }
                let select = self.recommendTitleBox.filter {$0.titleType == 0}
                self.RecommendTitleRelay.accept(self.recommendTitleBox)
            }
        }
    }
    
    func makeLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (section: Int, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            if GALLERY_SECTION.contains(section) {
                return LayoutBuilder.rectangleHorizonContinuousWithHeaderSection(collectionViewBounds: self.collectionView.bounds)
            } else if TEXT_SECTION.contains(section) {
                return LayoutBuilder.buildTextSectionLayout()
            } else {
                return LayoutBuilder.buildHorizontalTableSectionLayout()
            }
        }
        return layout
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 9
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch  section {
        case 0: return 1
        case 1: return RecommendArray1.count
        case 2: return RecommendArray2.count
        case 3: return 1
        case 4: return RecommendArray4.count
        case 5: return RecommendArray5.count
        case 6: return 1
        case 7: return RecommendArray7.count
        case 8: return RecommendArray8.count
        default:
            return 1
        }
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
        switch  indexPath.section {
            
        case 1:
            let url = URL(string: RecommendArray1[indexPath.row].blog_web_url)
            let safariView = SFSafariViewController(url: url!)
            present(safariView, animated: true)
        case 2:  let url = URL(string: RecommendArray2[indexPath.row].blog_web_url)
            let safariView = SFSafariViewController(url: url!)
            present(safariView, animated: true)
            
        case 4:  let url = URL(string: RecommendArray4[indexPath.row].blog_web_url)
            let safariView = SFSafariViewController(url: url!)
            present(safariView, animated: true)
            
        case 5:  let url = URL(string: RecommendArray5[indexPath.row].blog_web_url)
            let safariView = SFSafariViewController(url: url!)
            present(safariView, animated: true)
            
        case 7:  let url = URL(string: RecommendArray7[indexPath.row].blog_web_url)
            let safariView = SFSafariViewController(url: url!)
            present(safariView, animated: true)
            
        case 8:  let url = URL(string: RecommendArray8[indexPath.row].blog_web_url)
            let safariView = SFSafariViewController(url: url!)
            present(safariView, animated: true)
            
        default:
            let url = URL(string: RecommendArray1[indexPath.row].blog_web_url)
            let safariView = SFSafariViewController(url: url!)
            present(safariView, animated: true)
        }
    }
}
extension UIColor {
    static func rgb(red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor{
        return self.init(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
    }
}
