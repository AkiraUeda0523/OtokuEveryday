//  AppDelegate.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2021/09/09.
//
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
    // MARK: - アプリケーションのライフサイクル
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // FirebaseとGoogle Mobile Adsの設定
        configureFirebaseAndGoogleAds()
        // Realmの設定
        configureRealm()
        // 依存性注入の設定 (Swinject)
        setupDependencyInjection()
        // UserDefaultsに保存されているバージョンがない場合、初期化
        if UserDefaults.standard.value(forKey: "storedVersion") == nil {
            UserDefaults.standard.set(0, forKey: "storedVersion")
        }
        return true
    }
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Sceneセッションが破棄されたときに呼び出される（通常、アプリがバックグラウンドや終了したとき）
    }
    // MARK: - FirebaseとGoogle Adsの初期化
    private func configureFirebaseAndGoogleAds() {
        // Firebaseの初期化
        FirebaseApp.configure()
        // Google広告SDKの初期化
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
    // MARK: - Realmの設定
    private func configureRealm() {
        // テスト環境かどうかをチェック
        if ProcessInfo.processInfo.environment["IS_TESTING"] == "YES" {
            configureRealmForTesting()
            return
        }
        // Realmのスキーマバージョンとマイグレーション設定
        let config = Realm.Configuration(
            schemaVersion: 2,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 2 {
                    // マイグレーション時に新しいIDを生成して設定
                    migration.enumerateObjects(ofType: OtokuDataRealmModel.className()) { _, newObject in
                        let id = UUID().uuidString
                        newObject!["id"] = id
                    }
                }
            }
        )
        // Realmの設定を適用
        Realm.Configuration.defaultConfiguration = config
        // Realmの初期化とエラーハンドリング
        do {
            let realm = try Realm()
            //実際の保存場所のバス
            print("Realm path: \(realm.configuration.fileURL?.absoluteString ?? "")")
        } catch let error as NSError {
            print("Realmの初期化エラー: \(error.localizedDescription)")
        }
    }
       // MARK: - 依存性注入の設定
    private func setupDependencyInjection() {
        // Swinjectコンテナにモデルやマネージャーを登録
        container.register(AuthenticationManagerType.self) { _ in AuthenticationStateManager() }
            .inObjectScope(.container)

        container.register(MapModelType.self) { _ in MapModel() }
        container.register(SetAdMobModelType.self) { _ in SetAdMobModel() }
        container.register(FetchTodayDateModelType.self) { _ in FetchTodayDateModel() }
        container.register(AutoScrollModelType.self) { _ in AutoScrollModel() }
        
        // FirebaseとRealmを利用した共通データモデルの登録
        container.register(FetchCommonDataModelType.self) { _ in
            FetchCommonDataModel(dataFetcher: FirebaseFetcherModel(), dataStorage: RealmStorageModel(), versionManager: VersionManagementModel())
        }.inObjectScope(.container)

        container.register(FirestoreWrapperProtocol.self) { _ in FirestoreWrapper() }

        // ViewModelの依存性注入
        container.register(CalendarViewModel.self) { resolver in
            CalendarViewModel(
                authenticationManager: resolver.resolve(AuthenticationManagerType.self)!,
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
                commonDataModel: resolver.resolve(FetchCommonDataModelType.self)!,
                authenticationManager: resolver.resolve(AuthenticationManagerType.self)!,
                firestore: resolver.resolve(FirestoreWrapperProtocol.self)!
            )
        }
    }
    // MARK: -　テスト用
    private func configureRealmForTesting() {
        // テスト用
    }
}
