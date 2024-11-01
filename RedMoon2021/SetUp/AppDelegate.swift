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
import RxSwift
import RxCocoa
import RealmSwift

//@main//メインスレッドでUI実行しろ　　WKWebViewが絡んでる可能性
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let tabIndexRelay = BehaviorRelay<Int>(value: 0)
    private let disposeBag = DisposeBag()
    var window: UIWindow?


    //    再起動メソッドらしい　　didFinishLaunchingWithOptions
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        FirebaseApp.configure()
//--------------------------------------------------------------------

        if UserDefaults.standard.value(forKey: "storedVersion") == nil {
            UserDefaults.standard.set(0, forKey: "storedVersion")
        }
//--------------------------------------------------------------------
        let config = Realm.Configuration(
            schemaVersion: 2, // 現在のスキーマのバージョン
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 2 {
                    // スキーマのバージョンが 0 の場合、プライマリーキーを追加
                    migration.enumerateObjects(ofType: OtokuDataRealmModel.className()) { oldObject, newObject in
                        let id = UUID().uuidString
                        newObject!["id"] = id
                    }
                }
            })
//--------------------------------------------------------------------
        let currentSchemaVersion = config.schemaVersion
        print("Current schema version: \(currentSchemaVersion)")
//--------------------------------------------------------------------
        // デフォルトの Realm を設定する
        Realm.Configuration.defaultConfiguration = config
        do {
            let realm = try Realm()
            print("Realm path: \(realm.configuration.fileURL?.absoluteString ?? "")")
        } catch let error as NSError {
            print("Error opening realm: \(error.localizedDescription)")
        }
//おそらくstate⭐️--------------------------------------------------------------
        if let tabBarController = window?.rootViewController as? UITabBarController {
            tabIndexRelay.accept(tabBarController.selectedIndex)
            tabBarController.rx.didSelect
                .subscribe(onNext: { [unowned self] in
                    if let index = ($0 as? UITabBarController)?.selectedIndex {
                        self.tabIndexRelay.accept(index)
                    }
                })
                .disposed(by: disposeBag)
        }
//--------------------------------------------------------------------
        // 初期化
        GADMobileAds.sharedInstance().start(completionHandler: nil)

        //                    self.window = UIWindow(frame: UIScreen.main.bounds)
        //                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
        //                    let initialViewController = storyboard.instantiateViewController(withIdentifier: "calendar")
        //                    self.window?.rootViewController = initialViewController
        //                    self.window?.makeKeyAndVisible()
//------------------------------シュプラッシュ制御用
        let shouldShowAnimation: Bool
        let storyboard = UIStoryboard(name: "BaseTabBar", bundle: nil)
        let initialViewController: UIViewController
//------------------------------シュプラッシュ制御用
        if let lastAnimationDate = UserDefaults.standard.object(forKey: "lastAnimationDate") as? Date {
            let currentDate = Date()
            let timeInterval = currentDate.timeIntervalSince(lastAnimationDate)
            shouldShowAnimation = timeInterval >= 86400 // 86400 seconds = 1 day
        } else {
            shouldShowAnimation = true
        }
//------------------------------シュプラッシュ制御用
        if shouldShowAnimation {
            initialViewController = storyboard.instantiateViewController(withIdentifier: "map")
            UserDefaults.standard.set(Date(), forKey: "lastAnimationDate")
        } else {
            //               if let baseTabBarController = storyboard.instantiateViewController(withIdentifier: "Calendar") as? BaseTabBarController {
            if let baseTabBarController = storyboard.instantiateViewController(withIdentifier: "map") as? BaseTabBarController {
                initialViewController = baseTabBarController
            } else {
                print("Error: Could not instantiate BaseTabBarController.")
                return false
            }

        }
//--------------------------------------------------------------------------------------------
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = initialViewController
        self.window = window
        window.makeKeyAndVisible()
        //ーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーー
        return true
        //                let config = Realm.Configuration(
        //                    schemaVersion: 1, // 現在のスキーマのバージョン
        //                    migrationBlock: { migration, oldSchemaVersion in
        //                        if oldSchemaVersion < 1 {
        //                            // スキーマのバージョンが 0 の場合、プライマリーキーを追加
        //                            migration.enumerateObjects(ofType: OtokuDataRealmModel.className()) { oldObject, newObject in
        //                                let id = UUID().uuidString
        //                                newObject!["id"] = id
        //                            }
        //                        }
        //                    })
        //                // デフォルトの Realm を設定する
        //                Realm.Configuration.defaultConfiguration = config
        //                do {
        //                    let realm = try Realm()
        //                    print("Realm path: \(realm.configuration.fileURL?.absoluteString ?? "")")
        //                } catch let error as NSError {
        //                    print("Error opening realm: \(error.localizedDescription)")
        //              //  }
    }
    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {//⭐️
        if let viewController = UIApplication.shared.windows.first?.rootViewController {
            // 現在表示しているUIViewControllerを取得する
            print("現在表示しているViewController: \(viewController)")
        }
    }
}
//    func applicationWillEnterForeground(_ application: UIApplication) {
//            guard let rootViewController = window?.rootViewController else {
//                return
//            }
//            print("Current view controller:", rootViewController)
//        }
//        // 匿名認証(下記のメソッドがエラーなく終了すれば、認証完了する)
//        Auth.auth().signInAnonymously() { (authResult, error) in
//            if error != nil{
//                print("Auth Error :\(error!.localizedDescription)")
//            }
//            // 認証情報の取得
//            guard let user = authResult?.user else { return }
//            let isAnonymous = user.isAnonymous  // true
//            let uid = user.uid
//            return
//        }
