//
//  SetAdMobModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2023/01/03.
//

import RxSwift
import RxCocoa
import GoogleMobileAds//サポート関係⚠️

struct SetAdMobModelData{
    var size:CGFloat
    var VC:UIViewController
}
protocol SetAdMobModelInput {
    func setAdMob(viewWidthSize:CGFloat,Self:UIViewController)
}
protocol SetAdMobModelOutput {
    var SetAdMobModelObservable: Observable<GADBannerView> { get }
}
protocol SetAdMobModelType: SetAdMobModelInput,SetAdMobModelOutput{
    var input: SetAdMobModelInput { get }
    var output: SetAdMobModelOutput { get }
}
class SetAdMobModel{
    private let SetAdMobModelRelay = PublishRelay<GADBannerView>()
}
extension SetAdMobModel: SetAdMobModelInput{
    func setAdMob(viewWidthSize:CGFloat,Self:UIViewController) {
        let AdMobID = ""
        var admobView = GADBannerView()
        admobView = GADBannerView(adSize:GADAdSizeBanner)
        admobView.frame.size = CGSize(width:viewWidthSize, height:admobView.frame.height)
        admobView.adUnitID = AdMobID
        admobView.rootViewController = Self
        admobView.load(GADRequest())
        self.SetAdMobModelRelay.accept(admobView)
    }
}
extension SetAdMobModel: SetAdMobModelOutput{
    var SetAdMobModelObservable: Observable<GADBannerView>{
        return SetAdMobModelRelay.asObservable()
    }
}
extension SetAdMobModel: SetAdMobModelType{
    var input: SetAdMobModelInput { return self }
    var output: SetAdMobModelOutput { return self }
}



