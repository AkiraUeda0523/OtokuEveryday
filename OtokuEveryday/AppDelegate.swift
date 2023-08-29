//  AppDelegate.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2021/09/09.
//
import UIKit
import Firebase
import GoogleMobileAds
import RxSwift
import RxCocoa
import RealmSwift
import Swinject

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let container = Container()
    private let tabIndexRelay = BehaviorRelay<Int>(value: 0)
    private let disposeBag = DisposeBag()
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        container.register(CalendarModelType.self) { _ in CalendarModel() }
        container.register(MapModelType.self) { _ in MapModel() }
        container.register(SetAdMobModelType.self) { _ in SetAdMobModel() }
        container.register(FetchTodayDateModelType.self) { _ in FetchTodayDateModel() }
        container.register(AutoScrollModelType.self) { _ in AutoScrollModel() }
        container.register(FetchCommonDataModelType.self) { _ in FetchCommonDataModel() }
            .inObjectScope(.container)

        container.register(CalendarViewModel.self) { resolver in
            CalendarViewModel(
                calendarViewModel: resolver.resolve(CalendarModelType.self)!,
                adMobModel: resolver.resolve(SetAdMobModelType.self)!,
                fetchTodayDateModel: resolver.resolve(FetchTodayDateModelType.self)!,
                autoScrollModel: resolver.resolve(AutoScrollModelType.self)!,
                fetchCommonDataModel: resolver.resolve(FetchCommonDataModelType.self)!
            )!
        }

        container.register(MapViewModel.self) { resolver in
            MapViewModel(
                model: resolver.resolve(MapModelType.self)!,
                adMobModel: resolver.resolve(SetAdMobModelType.self)!,
                fetchTodayDateModel: resolver.resolve(FetchTodayDateModelType.self)!,
                commonDataModel: resolver.resolve(FetchCommonDataModelType.self)!
            )
        }

        FirebaseApp.configure()
        if UserDefaults.standard.value(forKey: "storedVersion") == nil {
            UserDefaults.standard.set(0, forKey: "storedVersion")
        }
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
        let currentSchemaVersion = config.schemaVersion
        print("Current schema version: \(currentSchemaVersion)")
        // デフォルトの Realm を設定する
        Realm.Configuration.defaultConfiguration = config
        do {
            let realm = try Realm()
            print("Realm path: \(realm.configuration.fileURL?.absoluteString ?? "")")
        } catch let error as NSError {
            print("Error opening realm: \(error.localizedDescription)")
        }
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
        // 初期化
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        let shouldShowAnimation: Bool
        if let lastAnimationDate = UserDefaults.standard.object(forKey: "lastAnimationDate") as? Date {
            let currentDate = Date()
            let timeInterval = currentDate.timeIntervalSince(lastAnimationDate)
            shouldShowAnimation = timeInterval >= 86400 // 86400 seconds = 1 day
        } else {
            shouldShowAnimation = true
        }
        let storyboard = UIStoryboard(name: "BaseTabBar", bundle: nil)
        let initialViewController: UIViewController
        if shouldShowAnimation {
            initialViewController = storyboard.instantiateViewController(withIdentifier: "map")
            UserDefaults.standard.set(Date(), forKey: "lastAnimationDate")
        } else {
            if let baseTabBarController = storyboard.instantiateViewController(withIdentifier: "map") as? BaseTabBarController {
                initialViewController = baseTabBarController
            } else {
                print("Error: Could not instantiate BaseTabBarController.")
                return false
            }
        }
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = initialViewController
        self.window = window
        window.makeKeyAndVisible()
        return true
    }
    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}
