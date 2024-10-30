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
// タブバーのアイテムプロパティを表す構造体
struct TabBarItemProperties {
    let selectedImageName: String
    let imageName: String
    let imageSize: CGSize
    let imageInsets: UIEdgeInsets
}
// MARK: - Main Class
class BaseTabBarController: UITabBarController, UITabBarControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        UITabBar.appearance().backgroundImage = UIImage()
        // 各タブバーアイテムのプロパティを定義
        let tabBarItemProperties: [TabBarItemProperties] = [
            // カレンダータブのプロパティ
            .init(selectedImageName: "calender5", imageName: "calender6", imageSize: .init(width: 80, height: 120), imageInsets: UIEdgeInsets(top: 21, left: 0, bottom: 0, right: 0)),
            // マップタブのプロパティ
            .init(selectedImageName: "MAP3", imageName: "MAP4", imageSize: .init(width: 60, height: 120), imageInsets: UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)),
            // おすすめタブのプロパティ
            .init(selectedImageName: "recommendation1", imageName: "recommendation2", imageSize: .init(width: 60, height: 120), imageInsets: UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)),
            // 検索タブのプロパティ
            .init(selectedImageName: "SEARCH3", imageName: "SEARCH4", imageSize: .init(width: 65, height: 120), imageInsets: UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0))
        ]
        // 各タブバーアイテムにプロパティを適用
        viewControllers?.enumerated().forEach { index, viewController in
            let properties = tabBarItemProperties[index]
            viewController.tabBarItem.selectedImage = UIImage(named: properties.selectedImageName)?.resize(size: properties.imageSize)?.withRenderingMode(.alwaysOriginal)
            viewController.tabBarItem.imageInsets = properties.imageInsets
            viewController.tabBarItem.image = UIImage(named: properties.imageName)?.resize(size: properties.imageSize)?.withRenderingMode(.alwaysOriginal)
            viewController.tabBarItem.tag = index
        }
    }
    // タブバーのアイテムが選択された時に呼ばれるメソッド
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        // タッチフィードバックを提供するためにシステムサウンドを再生
        AudioServicesPlaySystemSound(1519)
    }
}
