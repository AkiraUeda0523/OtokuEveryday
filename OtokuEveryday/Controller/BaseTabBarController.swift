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

class BaseTabBarController: UITabBarController,UITabBarControllerDelegate {
    let mapStateManagementModel = MapStateManagementModel.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        let test = tabBarController?.tabBar.frame.size.height

        UITabBar.appearance().backgroundImage = UIImage()

        viewControllers?.enumerated().forEach({(index, viewController) in
            switch index {
            case 0:
                viewController.tabBarItem.selectedImage = UIImage(named: "calender5")!.resize(size: .init(width: 80, height: 120))?.withRenderingMode(.alwaysOriginal)
                viewController.tabBarItem.imageInsets = UIEdgeInsets(top: 21, left: 0, bottom: 0, right: 0)
                viewController.tabBarItem.image = UIImage(named: "calender6")?.resize(size: .init(width: 80, height: 120))?.withRenderingMode(.alwaysOriginal)
                viewController.tabBarItem.tag = 0
            case 1:
                viewController.tabBarItem.selectedImage = UIImage(named: "MAP3")?.resize(size: .init(width:60, height: 120))?.withRenderingMode(.alwaysOriginal)
                viewController.tabBarItem.imageInsets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
                viewController.tabBarItem.image = UIImage(named: "MAP4")?.resize(size: .init(width: 60, height: 120))?.withRenderingMode(.alwaysOriginal)
                viewController.tabBarItem.tag = 1
            case 2:
                viewController.tabBarItem.selectedImage = UIImage(named: "recommendation1")?.resize(size: .init(width: 60, height: 120))?.withRenderingMode(.alwaysOriginal)
                viewController.tabBarItem.imageInsets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
                viewController.tabBarItem.image = UIImage(named: "recommendation2")?.resize(size: .init(width: 60, height: 120))?.withRenderingMode(.alwaysOriginal)
                viewController.tabBarItem.tag = 2
            case 3:
                viewController.tabBarItem.selectedImage = UIImage(named: "SEARCH3")?.resize(size: .init(width: 65, height: 120))?.withRenderingMode(.alwaysOriginal)
                viewController.tabBarItem.imageInsets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
                viewController.tabBarItem.image = UIImage(named: "SEARCH4")?.resize(size: .init(width: 65, height: 120))?.withRenderingMode(.alwaysOriginal)
                viewController.tabBarItem.tag = 3
            default:
                break
            }
        })
    }
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        switch item.tag {
        case 0:
            AudioServicesPlaySystemSound(1519)
            mapStateManagementModel.currentlyDisplayedVCRelay.accept(false)
        case 1:
            AudioServicesPlaySystemSound(1519)
            mapStateManagementModel.currentlyDisplayedVCRelay.accept(true)
        case 2:
            AudioServicesPlaySystemSound(1519)
            mapStateManagementModel.currentlyDisplayedVCRelay.accept(false)
        case 3:
            AudioServicesPlaySystemSound(1519)
            mapStateManagementModel.currentlyDisplayedVCRelay.accept(false)

        default:
            break
        }
    }
    //    これ何！？⚠️
    private func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        if viewController is TabBarDelegate {
            let v = viewController as! TabBarDelegate
            v.didSelectTab(tabBarController: self)
        }
    }

    func tabBarController(
        _ tabBarController: UITabBarController,
        didSelect viewController: UIViewController) {
            if let topViewController: UIViewController = topViewController(controller:viewController){
                mapStateManagementModel.currentlyDisplayedVCRelay.accept(topViewController is MapViewController)
            }
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
