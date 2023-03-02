//
//  SetAdMobModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2023/01/03.
//

import Foundation
import GoogleMobileAds//サポート関係⚠️

class SetAdMobModel{

    let AdMobID = "xxxxxxxxxxxxxxxxxxxxxxxxx"

    
    static func setAdMob(bannerView:UIView,view:UIView,Self:UIViewController){
        let AdMobID = "xxxxxxxxxxxxxxxxxxxxxxxxx"
        var admobView = GADBannerView()
        admobView = GADBannerView(adSize:GADAdSizeBanner)
        admobView.frame.size = CGSize(width:view.frame.width, height:admobView.frame.height)
        admobView.adUnitID = AdMobID
        admobView.rootViewController = Self
        bannerView.addSubview(admobView)
        admobView.load(GADRequest())

    }

}


