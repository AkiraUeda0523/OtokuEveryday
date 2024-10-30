import RxSwift
import RxCocoa
import GoogleMobileAds

struct SetAdMobModelData {
    var bannerWidth: CGFloat
    var bannerHeight: CGFloat
    var VC: UIViewController
}
// MARK: - Protocols
protocol SetAdMobModelInput {
    func setAdMob(bannerWidthSize: CGFloat, bannerHeight: CGFloat, viewController: UIViewController)
}
protocol SetAdMobModelOutput {
    var SetAdMobModelObservable: Observable<AdBannerView> { get }
}
protocol SetAdMobModelType: SetAdMobModelInput, SetAdMobModelOutput {
    var input: SetAdMobModelInput { get }
    var output: SetAdMobModelOutput { get }
}
protocol AdBannerView {
    var adUnitID: String? { get set }
    var rootViewController: UIViewController? { get set }
    func loadAd(_ request: GADRequest!)
}
// MARK: - Main Class
class SetAdMobModel: NSObject {
    private let SetAdMobModelRelay = PublishRelay<AdBannerView>()
    private var currentBannerView: GADBannerView?
}

// MARK: - Input Implementation
extension SetAdMobModel: SetAdMobModelInput, GADBannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("Ad loaded successfully")
        // バリアブロックを使用して処理の順序を保証
        DispatchQueue.main.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            let bannerAdSize = bannerView.adSize.size
            let bannerFrameSize = bannerView.frame.size
            print("Expected Banner Ad Size: \(bannerAdSize.width) x \(bannerAdSize.height)")
            print("Actual Banner Frame Size: \(bannerFrameSize.width) x \(bannerFrameSize.height)")
            if bannerAdSize == bannerFrameSize {
                print("Banner size is correct.")
                // レイアウトを強制的に更新
                bannerView.setNeedsLayout()
                bannerView.layoutIfNeeded()
                print("Expected Banner Ad Size２: \(bannerAdSize.width) x \(bannerAdSize.height)")
                print("Actual Banner Frame Size２: \(bannerFrameSize.width) x \(bannerFrameSize.height)")
                // 広告コンテンツが完全にロードされたことを確認してから処理
                if bannerView.responseInfo != nil {
                    // 他の処理が完了するのを待ってから広告を表示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        print("Banner view accepted to relay")
                        self.SetAdMobModelRelay.accept(bannerView)
                    }
                }
            }
        }
    }
    
    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        print("Ad failed to load with error: \(error.localizedDescription)")
        // エラー時の再試行処理
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let request = GADRequest()
            request.scene = bannerView.rootViewController?.view.window?.windowScene
            bannerView.load(request)
        }
    }
    
    func setAdMob(bannerWidthSize: CGFloat, bannerHeight: CGFloat, viewController: UIViewController) {
        DispatchQueue.main.async {
            guard bannerWidthSize > 0 else {
                print("Invalid banner width.")
                return
            }
            self.cleanup()
            let admobView = GADBannerView()
            // アダプティブバナーのサイズを設定
            let adaptiveSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(bannerWidthSize)
            admobView.adSize = adaptiveSize
            GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = ["xxxxxxxxxxxxxxx"]
            print("Test device identifiers: \(GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers ?? [])")
            admobView.clipsToBounds = true
            admobView.layer.shouldRasterize = true
            admobView.layer.rasterizationScale = UIScreen.main.scale
            admobView.adUnitID = self.getAdMobID(for: viewController)
            admobView.rootViewController = viewController
            admobView.delegate = self
            self.currentBannerView = admobView
            let request = GADRequest()
            request.scene = viewController.view.window?.windowScene
            // URLSessionの競合を避けるため、少し遅延を入れる
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                admobView.load(request)
            }
        }
    }
    
    private func getAdMobID(for viewController: UIViewController) -> String {
        if viewController is CalendarViewController {
            return "xxxxxx"
        } else if viewController is MapViewController {
            return "xxxxxx"
        } else if viewController is RecommendationArticleController {
            return "xxxxxx"
        }else if viewController is  CategoryViewController {
            return "xxxxxx"
        }
        return "xxxxxx"
    }
    private func setupBannerConstraints(bannerView: GADBannerView, in containerView: UIView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        let bannerHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: 60) // 仮の高さ
        bannerHeightConstraint.priority = .defaultHigh // 高さを変える余地を残す
        NSLayoutConstraint.activate([
            bannerView.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor),
            bannerView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            bannerHeightConstraint
        ])
    }
}
// MARK: - Output Implementation
extension SetAdMobModel: SetAdMobModelOutput {
    var SetAdMobModelObservable: Observable<AdBannerView> {
        return SetAdMobModelRelay.asObservable()
    }
}
// MARK: - Additional Extensions
extension SetAdMobModel: SetAdMobModelType {
    var input: SetAdMobModelInput { return self }
    var output: SetAdMobModelOutput { return self }
}
// MARK: -
extension GADBannerView: AdBannerView {
    func loadAd(_ request: GADRequest!) {
        self.load(request)
    }
}
// MARK: - Cleanup Method
extension SetAdMobModel {
    func cleanup() {
        if let existingBanner = currentBannerView {
            existingBanner.delegate = nil
            existingBanner.rootViewController = nil
            existingBanner.removeFromSuperview()
            currentBannerView = nil
            print("Existing banner cleaned up.")
        }
    }
}

//オートレイアウトのエラーが出ている
//Unable to simultaneously satisfy constraints


//・ターゲットIDとFirestoreの応答：
//FirestoreにおけるWatchStreamのターゲットIDの追加と削除が頻繁に行われており、データの読み込みやキャンセルが多発しています。特に複数のターゲットIDが同時にトラッキングされる場合、一部のビューでFirestoreデータが更新されるたびにレイアウトがリフレッシュされ、バナーの位置がずれる可能性があります。

//・upload(for:fromFile:)やurlSession(_:needNewBodyStreamForTask:)メソッドの警告：
//「upload(for:fromFile:)」関連の警告が出ている点は、FirebaseまたはAdMob SDKが期待するアップロード形式が異なる可能性があり、この影響でレイアウトや表示に遅延が生じている可能性も考えられます。
//
//・Firestoreデータ更新の頻度：
//Firestoreでターゲットの追加・削除が頻繁に発生しており、これがUIリフレッシュの引き金となっている可能性はありますが、これはオートレイアウトの乱れではなくデータ更新の影響と考えられます


//気になるエラーメッセージ
//The request of a upload task should not contain a body or a body stream, use upload(for:fromFile:), upload(for:from:), or supply the body stream through the urlSession(_:needNewBodyStreamForTask:) delegate method.


//広告の読み込みから表示までの間に他の処理（Firestoreの操作など）が入っています。


//広告イベントの順序
//ad_query (_aq) → Banner added to view → ad_impression (_ai)

