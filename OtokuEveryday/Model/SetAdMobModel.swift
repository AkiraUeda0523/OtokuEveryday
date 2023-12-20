////
////  SetAdMobModel.swift
////  RedMoon2021
////
////  Created by 上田晃 on 2023/01/03.
////
//

import RxSwift
import RxCocoa
import GoogleMobileAds

struct SetAdMobModelData {
    var bannerWidth: CGFloat
    var bannerHight: CGFloat
    var VC: UIViewController
}
//MARK: -
protocol SetAdMobModelInput {
    func setAdMob(bannerWidthSize: CGFloat,bannerHight: CGFloat, viewController: UIViewController)
}

protocol SetAdMobModelOutput {
    var SetAdMobModelObservable: Observable<AdBannerView> { get }  // AdBannerViewを使用
}

protocol SetAdMobModelType: SetAdMobModelInput, SetAdMobModelOutput {
    var input: SetAdMobModelInput { get }
    var output: SetAdMobModelOutput { get }
}

//MARK: -
protocol AdBannerView {
    var adUnitID: String? { get set }
    var rootViewController: UIViewController? { get set }
    func loadAd(_ request: GADRequest!)
}

//MARK: -
class SetAdMobModel {
    private let SetAdMobModelRelay = PublishRelay<AdBannerView>()
}
extension SetAdMobModel: SetAdMobModelInput {
    
    func setAdMob(bannerWidthSize: CGFloat,bannerHight: CGFloat, viewController: UIViewController) {
        guard bannerWidthSize > 0, bannerHight > 0 else {
            print("Error: Width or height is not valid (must be greater than 0)")
            return
        }
        let AdMobID = "XXXXXXXXXXXXXXXXXX"
        var admobView: AdBannerView = GADBannerView()
        let customSize = GADAdSizeFromCGSize(CGSize(width: bannerWidthSize, height: bannerHight))
        (admobView as! GADBannerView).adSize = customSize
        admobView.adUnitID = AdMobID
        admobView.rootViewController = viewController //
        admobView.loadAd(GADRequest())
        self.SetAdMobModelRelay.accept(admobView)
    }
}

extension SetAdMobModel: SetAdMobModelOutput {
    var SetAdMobModelObservable: Observable<AdBannerView> {
        return SetAdMobModelRelay.asObservable()
    }
}

extension SetAdMobModel: SetAdMobModelType {
    var input: SetAdMobModelInput { return self }
    var output: SetAdMobModelOutput { return self }
}

//MARK: -
extension GADBannerView: AdBannerView {
    func loadAd(_ request: GADRequest!) {
        self.load(request)
    }
}
