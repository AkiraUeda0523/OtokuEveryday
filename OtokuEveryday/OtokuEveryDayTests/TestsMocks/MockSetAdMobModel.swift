//
//  MockSetAdMobModel.swift
//  RedMoon2021Tests
//
//  Created by 上田晃 on 2023/10/31.
//

@testable import RedMoon2021
import UIKit
import RxSwift

class MockSetAdMobModel: SetAdMobModelType, SetAdMobModelInput, SetAdMobModelOutput {
    
    var mockAdMobView: MockGADBannerView = MockGADBannerView()
    var input: SetAdMobModelInput { return self }
    var output: SetAdMobModelOutput { return self }
    var setAdMobCalledWith: (bannerWidthSize: CGFloat,bannerHight: CGFloat, VC: UIViewController)?
    
    lazy var SetAdMobModelObservable: Observable<AdBannerView> = {
        if let adBannerView = mockAdMobView as? AdBannerView {
            return Observable.just(adBannerView)
        } else {
            return Observable.error(NSError(domain: "com.yourdomain.appname", code: 9999, userInfo: [NSLocalizedDescriptionKey: "Casting Error"]))
        }
    }()
    
    func setAdMob(bannerWidthSize: CGFloat, bannerHight: CGFloat, viewController: UIViewController) {
        setAdMobCalledWith = (bannerWidthSize: bannerWidthSize,bannerHight: bannerHight, VC: viewController)
    }
}
