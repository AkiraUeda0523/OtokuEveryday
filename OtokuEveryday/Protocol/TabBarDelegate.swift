//
//  TabBarDelegate.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2022/02/19.
//

import Foundation

@objc protocol TabBarDelegate {
    func didSelectTab(tabBarController: BaseTabBarController)
}
