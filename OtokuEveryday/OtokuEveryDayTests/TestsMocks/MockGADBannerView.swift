//
//  MockGADBannerView.swift
//  RedMoon2021Tests
//
//  Created by 上田晃 on 2023/10/31.
//

import UIKit

class MockGADBannerView: UIView {
    var adUnitID: String?
    var rootViewController: UIViewController?
    var didLoadAd: Bool = false
    
    func loadAd(_ request: Any) {
        self.didLoadAd = true
    }
}
