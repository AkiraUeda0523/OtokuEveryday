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
    private let disposeBag = DisposeBag()
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // テスト環境なのか確認
        if ProcessInfo.processInfo.environment["IS_TESTING"] == "YES" {
            
            FirebaseApp.configure()
            
            if UserDefaults.standard.value(forKey: "storedVersion") == nil {
                UserDefaults.standard.set(0, forKey: "storedVersion")
            }
            let config = Realm.Configuration(
                schemaVersion: 2,
                migrationBlock: { migration, oldSchemaVersion in
                    if oldSchemaVersion < 2 {
                        migration.enumerateObjects(ofType: OtokuDataRealmModel.className()) { oldObject, newObject in
                            let id = UUID().uuidString
                            newObject!["id"] = id
                        }
                    }
                })
            let currentSchemaVersion = config.schemaVersion
            print("Current schema version: \(currentSchemaVersion)")
            let currentStoredVersion = UserDefaults.standard.integer(forKey: "storedVersion")
            print("Current stored version in UserDefaults: \(currentStoredVersion)")
            Realm.Configuration.defaultConfiguration = config
            do {
                let realm = try Realm()
                print("Realm path: \(realm.configuration.fileURL?.absoluteString ?? "")")
            } catch let error as NSError {
                print("Error opening realm: \(error.localizedDescription)")
            }
            // 初期化
            GADMobileAds.sharedInstance().start(completionHandler: nil)
            
            return true
        }
        
        FirebaseApp.configure()
        
        container.register(CalendarModelType.self) { _ in CalendarModel() }
        container.register(MapModelType.self) { _ in MapModel() }
        container.register(SetAdMobModelType.self) { _ in SetAdMobModel() }
        container.register(FetchTodayDateModelType.self) { _ in FetchTodayDateModel() }
        container.register(AutoScrollModelType.self) { _ in AutoScrollModel() }
        container.register(FetchCommonDataModelType.self) { _ in FetchCommonDataModel(dataFetcher: FirebaseFetcher(), dataStorage: RealmStorage(), versionManager: UserDefaultsVersionManager()) }
            .inObjectScope(.container)//シングルトンの様に
        
        container.register(CalendarViewModel.self) { resolver in
            CalendarViewModel(
                calendarModel: resolver.resolve(CalendarModelType.self)!,
                adMobModel: resolver.resolve(SetAdMobModelType.self)!,
                todayDateModel: resolver.resolve(FetchTodayDateModelType.self)!,
                autoScrollModel: resolver.resolve(AutoScrollModelType.self)!,
                commonDataModel: resolver.resolve(FetchCommonDataModelType.self)!
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
        let currentStoredVersion = UserDefaults.standard.integer(forKey: "storedVersion")
        print("Current stored version in UserDefaults: \(currentStoredVersion)")
        // デフォルトの Realm を設定する
        Realm.Configuration.defaultConfiguration = config
        do {
            let realm = try Realm()
            print("Realm path: \(realm.configuration.fileURL?.absoluteString ?? "")")
        } catch let error as NSError {
            print("Error opening realm: \(error.localizedDescription)")
        }
        // 初期化
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}

