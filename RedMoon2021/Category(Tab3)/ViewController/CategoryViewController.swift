////
////  CategoryViewController.swift
////  RedMoon2021
////
////  Created by 上田晃 on 2021/11/18.
import UIKit
import ViewAnimator
import AudioToolbox
import SafariServices
import RxSwift
import GoogleMobileAds

class CategoryViewController: UIViewController {
    @IBOutlet weak var otherOtokuTableView: UITableView!
    @IBOutlet weak var adMobBanner: UIView!
    private var admobBannerView: GADBannerView?
    private var disposeBag = DisposeBag()
    var otokuArray = ["新着記事", "フード", "レジャー", "ビューティ", "サブスク", "ビジネス", "エブ子のお得日記"]
    var imageArray = ["0", "1", "2", "3", "4", "5", "6"]
    private var dataSource: UITableViewDiffableDataSource<Section, String>!
    let adMobModel = SetAdMobModel()
    enum Section {
        case main
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = UITableViewDiffableDataSource<Section, String>(tableView: otherOtokuTableView) { (tableView, indexPath, itemName) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! OtherOtokuCustomCell
            cell.otherOtokuLabel.text = itemName
            cell.otherOtokuImage.image = UIImage(named: self.imageArray[indexPath.row])
            return cell
        }
        var snapshot = NSDiffableDataSourceSnapshot<Section, String>()
        snapshot.appendSections([.main])
        snapshot.appendItems(otokuArray, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
        otherOtokuTableView.delegate = self
        setMapAdMobBanner()
        setupAdMobBannerLayout()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.backgroundColor = .systemRed
        let animation = [AnimationType.vector(CGVector(dx: 0, dy: 30))]
        UIView.animate(views: otherOtokuTableView.visibleCells, animations: animation, completion: nil)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
}
extension CategoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        AudioServicesPlaySystemSound(1519)
        let urls = [
            "https://otoku-everyday.com/category/new/",
            "https://otoku-everyday.com/category/food/",
            "https://otoku-everyday.com/category/leisure/",
            "https://otoku-everyday.com/category/beauty/",
            "https://otoku-everyday.com/category/subscription/",
            "https://otoku-everyday.com/category/business/",
            "https://otoku-everyday.com/category/blogdeotoku/"
        ]
        if indexPath.row < urls.count {
            openURL(urls[indexPath.row])
        }
    }
    func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            let safariView = SFSafariViewController(url: url)
            present(safariView, animated: true)
        }
    }
    private func setupAdMobBannerLayout() {
        // 背景色を白に設定
        adMobBanner.backgroundColor = .clear
        // 自動レイアウト設定
        adMobBanner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            adMobBanner.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor), // ボトムはセーフエリアに揃える
            adMobBanner.leadingAnchor.constraint(equalTo: view.leadingAnchor), // 左端
            adMobBanner.trailingAnchor.constraint(equalTo: view.trailingAnchor), // 右端
            adMobBanner.heightAnchor.constraint(equalToConstant: 61) // 高さは61に設定
        ])
    }
    private func setMapAdMobBanner() {
        // adMobBanner にバナーが既に存在する場合は何もしない
        guard adMobBanner.subviews.isEmpty else {
            return
        }
        // 広告バナーを ViewModel から取得して設定する
        adMobModel
            .output
            .SetAdMobModelObservable
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] setAdMob in
                guard let self = self, let bannerView = setAdMob as? GADBannerView else { return }
                bannerView.translatesAutoresizingMaskIntoConstraints = false
                self.adMobBanner.addSubview(bannerView)
                NSLayoutConstraint.activate([
                    bannerView.leadingAnchor.constraint(equalTo: self.adMobBanner.leadingAnchor),
                    bannerView.trailingAnchor.constraint(equalTo: self.adMobBanner.trailingAnchor),
                    bannerView.topAnchor.constraint(equalTo: self.adMobBanner.topAnchor),
                    bannerView.heightAnchor.constraint(equalToConstant: 61)
                ])
            })
            .disposed(by: disposeBag)
        // バナーサイズを ViewModel に通知して設定
        adMobModel.setAdMob(bannerWidthSize: adMobBanner.frame.width, bannerHeight: 61, viewController: self)
    }
}
