//
//  AppDelegate.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2021/09/09.
//

import UIKit
import Firebase
import FirebaseAuth
import GoogleMobileAds
import SVGKit
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth


@main//メインスレッドでUI実行しろ　　WKWebViewが絡んでる可能性
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        // 匿名認証(下記のメソッドがエラーなく終了すれば、認証完了する)
        Auth.auth().signInAnonymously() { (authResult, error) in
            if error != nil{
                print("Auth Error :\(error!.localizedDescription)")
            }
            // 認証情報の取得
            guard let user = authResult?.user else { return }
            let isAnonymous = user.isAnonymous  // true
            let uid = user.uid
            return
        }
        // 初期化
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        return true
    }
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

