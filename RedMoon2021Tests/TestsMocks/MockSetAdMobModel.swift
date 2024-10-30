//
//  MockSetAdMobModel.swift
//  RedMoon2021Tests
//
//  Created by 上田晃 on 2023/10/31.
//

@testable import RedMoon2021
import UIKit
import RxSwift

// ここにダミーのGADBannerViewを定義
class MockSetAdMobModel: SetAdMobModelType, SetAdMobModelInput, SetAdMobModelOutput {
    // ダミーデータのプロパティ
    var mockAdMobView: MockGADBannerView = MockGADBannerView()  // ここで初期化
    var input: SetAdMobModelInput { return self }
    var output: SetAdMobModelOutput { return self }
    var setAdMobCalledWith: (bannerWidthSize: CGFloat, bannerHight: CGFloat, VC: UIViewController)?
    // SetAdMobModelOutput の Observable
    lazy var SetAdMobModelObservable: Observable<AdBannerView> = {
        if let adBannerView = mockAdMobView as? AdBannerView {
            return Observable.just(adBannerView)
        } else {
            // キャストに失敗した場合の処理
            return Observable.error(NSError(domain: "com.yourdomain.appname", code: 9999, userInfo: [NSLocalizedDescriptionKey: "Casting Error"]))
        }
    }()
    func setAdMob(bannerWidthSize: CGFloat, bannerHight: CGFloat, viewController: UIViewController) {
        // このメソッドが呼ばれたときの引数をキャッシュ
        setAdMobCalledWith = (bannerWidthSize: bannerWidthSize, bannerHight: bannerHight, VC: viewController)
    }
}
