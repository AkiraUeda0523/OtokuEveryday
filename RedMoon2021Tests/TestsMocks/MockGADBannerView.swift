//
//  MockGADBannerView.swift
//  RedMoon2021Tests
//
//  Created by 上田晃 on 2023/10/31.
//

import UIKit

class MockGADBannerView: UIView { // UIViewを継承
    var adUnitID: String?
    var rootViewController: UIViewController?
    var didLoadAd: Bool = false
    func loadAd(_ request: Any) { // 引数の型をAnyに変更
        // モックの振る舞いはここに実装
        self.didLoadAd = true
    }
}
