
//  FetchCommonDataModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2023/02/02.
import Foundation
import RxSwift
import Firebase
import RxCocoa
import RealmSwift
import Network
// MARK: - Protocols
// 入力プロトコル: データのフェッチとUIの更新に関する処理を定義
protocol FetchCommonDataModelInput {
    func isRealmDataEmpty() async
    func updateUIFromRealmData()
}
// 出力プロトコル: 外部へのデータの提供に関する処理を定義
protocol FetchCommonDataModelOutput {
    var fetchCommonDataModelObservable: Observable<[OtokuDataModel]> { get }
    var shouldUpdateDataObservable: Observable<Bool> { get }
}
// 全体の型プロトコル: 入出力の定義を統合
protocol FetchCommonDataModelType {
    var input: FetchCommonDataModelInput { get }
    var output: FetchCommonDataModelOutput { get }
}
// MARK: - Main Class
// データフェッチと保存、バージョン管理を行う中心的なクラス
final class FetchCommonDataModel {
    private let otokuDataModelRelay = BehaviorRelay<[OtokuDataModel]>(value: [])
    private var firebaseVersion: Int?
    private let firebaseFetcher: FirebaseFetcher
    private let realmStorage: RealmStorage
    private var userDefaultsVersion: UserDefaultsVersion
    private let disposeBag = DisposeBag()
    //インクリメントしているかの判断用Bool
    private let shouldUpdateDataJudge = PublishSubject<Bool>()
    
    init(dataFetcher: FirebaseFetcher, dataStorage: RealmStorage, versionManager: UserDefaultsVersion) {
        self.firebaseFetcher = dataFetcher
        self.realmStorage = dataStorage
        self.userDefaultsVersion = versionManager
    }
}
// MARK: - Input Implementation
extension FetchCommonDataModel: FetchCommonDataModelInput {
    func isRealmDataEmpty() async {
        do {
            // Firebaseバージョンを取得
            let firebaseVersion = try await firebaseFetcher.firebaseFetchVersion()
            // レルムが空かどうかを確認
            if realmStorage.realmObjectsIsEmpty() {
                // レルムが空の場合はFirebaseからデータを取得してUIを更新
                await fetchDataFromFirebaseAndRealmUpdate(firebaseVersion: firebaseVersion)
            } else {
                // バージョンに応じてUIを更新
                await userDefaultsVersionJudge(firebaseVersion: firebaseVersion)
            }
        } catch {
            // バージョン取得に失敗した場合はRealmデータでUIを更新
            updateUIFromRealmData()
        }
    }
    private func userDefaultsVersionJudge(firebaseVersion: Int) async {
        do {
            // UserDefaultsのバージョン番号を取得
            guard let userDefaultsVersionNumber = userDefaultsVersion.userDefaultsVersionNumber else {
                // UserDefaultsのバージョンがない場合は適切な処理を行う
                updateUIFromRealmData()
                return
            }
            // UserDefaultsのバージョンとFirebaseのバージョンを比較
            if userDefaultsVersionNumber < firebaseVersion {
                // バージョンが古い場合はFirebaseからUI更新
                await fetchDataFromFirebaseAndRealmUpdate(firebaseVersion: firebaseVersion)
                shouldUpdateDataJudge.onNext(true)
            } else {
                // 同じバージョンの場合はRealmデータでUI更新
                updateUIFromRealmData()
                shouldUpdateDataJudge.onNext(false)
            }
        }
    }
    // Firebaseからデータを取得し、Realmに保存し、UIを更新する
    private func fetchDataFromFirebaseAndRealmUpdate(firebaseVersion: Int) async {
        do {
            // Firebaseからデータを非同期で取得
            let otokuData = try await firebaseFetcher.firebaseFetchData()
            // FirebaseデータをRealmに保存
            try realmStorage.saveToRealm(otokuData)
            // FirebaseバージョンをUserDefaultsに保存
            userDefaultsVersion.userDefaultsVersionNumber = firebaseVersion
            // Realmデータを使ってUIを更新
            updateUIFromRealmData()
        } catch {
            updateUIFromRealmData()  // 取得や保存に失敗した場合はRealmのデータでUIを更新
            print("Error during Firebase or Realm operation: \(error)")
        }
    }
    // Realmからデータを取得し、UIに反映させるメソッド
    func updateUIFromRealmData()  {
        // Realmからデータを取得
        let otokuDataList =  realmStorage.formatOtokuDataFromRealm()
        // 取得したデータをBehaviorRelayを使ってUIに反映
        self.otokuDataModelRelay.accept(otokuDataList)
    }
}
// MARK: - Output Implementation
extension FetchCommonDataModel: FetchCommonDataModelOutput {
    var shouldUpdateDataObservable: RxSwift.Observable<Bool> {
        shouldUpdateDataJudge.asObservable()
    }
    var fetchCommonDataModelObservable: Observable<[OtokuDataModel]> {
        return otokuDataModelRelay.asObservable().share(replay: 1) // Swinjectでシングルトン化している為、.share(replay: 1)不要か？
    }
}
// MARK: - Additional Extensions
extension FetchCommonDataModel: FetchCommonDataModelType {
    var input: FetchCommonDataModelInput { return self }
    var output: FetchCommonDataModelOutput { return self }
}
//-------------------------------------------------------------------
//// バックグラウンドスレッドでクエリを実行
//DispatchQueue.global().async {
//    autoreleasepool {
//        let realm = try! Realm()
//        let objects = realm.objects(MyObject.self) // 重いクエリを実行
//
//        // メインスレッドに戻る
//        DispatchQueue.main.async {
//            // クエリ結果を使用（例: UIの更新）
//        }
//    }
//}
