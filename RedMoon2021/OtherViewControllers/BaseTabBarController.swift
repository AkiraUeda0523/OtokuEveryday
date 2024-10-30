//
//  BaseTabBarController.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2021/09/13.
//

import UIKit
import AudioToolbox
import RxSwift
import RxRelay


struct TabBarItemProperties {
    let selectedImageName: String
    let imageName: String
    let imageSize: CGSize
    let imageInsets: UIEdgeInsets
}


class BaseTabBarController: UITabBarController,UITabBarControllerDelegate {
//    let mapStateManagementModel = MapStateManagementModel.shared
    private let mapViewModel: MapViewModelType

    required init?(coder: NSCoder) {
        mapViewModel = MapViewModel(model: MapModel(), adMobModel: SetAdMobModel(), fetchTodayDateModel: FetchTodayDateModel())//不要　ここにモックを差し込む（ちなみにVCも抽象化でテスト可能。UIテスト）
        super.init(coder: coder)

    }


    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self

        UITabBar.appearance().backgroundImage = UIImage()

        let tabBarItemProperties: [TabBarItemProperties] = [
            .init(selectedImageName: "calender5", imageName: "calender6", imageSize: .init(width: 80, height: 120), imageInsets: UIEdgeInsets(top: 21, left: 0, bottom: 0, right: 0)),
            .init(selectedImageName: "MAP3", imageName: "MAP4", imageSize: .init(width: 60, height: 120), imageInsets: UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)),
            .init(selectedImageName: "recommendation1", imageName: "recommendation2", imageSize: .init(width: 60, height: 120), imageInsets: UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)),
            .init(selectedImageName: "SEARCH3", imageName: "SEARCH4", imageSize: .init(width: 65, height: 120), imageInsets: UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0))
        ]
        viewControllers?.enumerated().forEach { index, viewController in
            let properties = tabBarItemProperties[index]
            viewController.tabBarItem.selectedImage = UIImage(named: properties.selectedImageName)?.resize(size: properties.imageSize)?.withRenderingMode(.alwaysOriginal)
            viewController.tabBarItem.imageInsets = properties.imageInsets
            viewController.tabBarItem.image = UIImage(named: properties.imageName)?.resize(size: properties.imageSize)?.withRenderingMode(.alwaysOriginal)
            viewController.tabBarItem.tag = index
        }

    }
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        AudioServicesPlaySystemSound(1519)
    }

    func topViewController(controller: UIViewController?) -> UIViewController? {
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}


//    これ何！？⚠️
//    private func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
//        if viewController is TabBarDelegate {
//            let v = viewController as! TabBarDelegate
//            v.didSelectTab(tabBarController: self)
//        }
//    }

//    func tabBarController(
//        _ tabBarController: UITabBarController,
//        didSelect viewController: UIViewController) {
//            if let topViewController: UIViewController = topViewController(controller:viewController){
//                mapViewModel.input.currentlyDisplayedVCRelay.onNext(topViewController is MapViewController)
//            }
//        }
