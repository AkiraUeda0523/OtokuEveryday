//
//  FetchCommonDataModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2023/02/02.
//

import Foundation
import RxSwift
import Firebase
import RxCocoa
import RealmSwift

enum FirebaseFetcherError: Error {
    case invalidVersionData
    case invalidOtokuData
}
// プロトコルの定義
protocol DataFetcher {
    func fetchVersion(completion: @escaping (Result<Int, Error>) -> Void)
    func fetchData(completion: @escaping (Result<[Any], Error>) -> Void)
}
protocol DataStorage {
    func saveData(_ data: [Any], completion: @escaping (Result<Void, Error>) -> Void)
    func retrieveData() -> [Any]
    func isEmpty() -> Bool
}
protocol VersionManager {
    var storedVersion: Int? { get set }
}
// 具体的なFirebaseの実装
class FirebaseFetcher: DataFetcher {
    
    func fetchVersion(completion: @escaping (Result<Int, Error>) -> Void) {
        let versionRef = Database.database().reference().child(Constants.versionKey)
        versionRef.observeSingleEvent(of: .value) { snapshot in
            guard let version = snapshot.value as? Int else {
                completion(.failure(FirebaseFetcherError.invalidVersionData))
                return
            }
            completion(.success(version))
        }
    }
    func fetchData(completion: @escaping (Result<[Any], Error>) -> Void) {
        let ref = Database.database().reference().child("OtokuDataModelsObject")
        ref.observeSingleEvent(of: .value) { snapshot in
            guard let data = snapshot.value as? [Any] else {
                completion(.failure(FirebaseFetcherError.invalidOtokuData))
                return
            }
            completion(.success(data))
        }
    }
}
// 具体的なRealmの実装
class RealmStorage: DataStorage {
    // データを保存する
    func saveData(_ data: [Any], completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let realm = try Realm()
            try realm.write {
                for item in data {
                    if let otokuData = item as? OtokuDataModel {
                        let otokuDataDictionary = otokuData.toDictionary() // OtokuDataModel がこのメソッドを持っていると仮定
                        if let otokuRealmModel = OtokuDataRealmModel.from(dictionary: otokuDataDictionary) {
                            realm.add(otokuRealmModel)
                        }
                    }
                }
                completion(.success(()))
            }
        } catch {
            completion(.failure(error))
        }
    }
    // データを取得する
    func retrieveData() -> [Any] {
        let realm: Realm
        do {
            realm = try Realm()
            let otokuDataBox = realm.objects(OtokuDataRealmModel.self)
            return otokuDataBox.map(OtokuDataModel.from)
        } catch {
            print("Error initializing Realm: \(error.localizedDescription)")
            return []
        }
    }
    // Realmのデータが空かどうかを確認する
    func isEmpty() -> Bool {
        do {
            let realm = try Realm()
            let otokuDataBox = realm.objects(OtokuDataRealmModel.self)
            return otokuDataBox.isEmpty
        } catch {
            print("Error initializing Realm: \(error.localizedDescription)")
            return true // エラーが発生した場合は、データが空であるとみなす
        }
    }
}
// UserDefaultsによるバージョン管理の実装
class UserDefaultsVersionManager: VersionManager {
    var storedVersion: Int? {
        get {
            return UserDefaults.standard.value(forKey: Constants.storedVersionKey) as? Int
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.storedVersionKey)
        }
    }
}
// MARK: -
private enum Constants {
    static let versionKey = "version"
    static let storedVersionKey = "storedVersion"
    static let timeoutSeconds: Double = 5.0
}
protocol FetchCommonDataModelInput {
    func bindFetchData()
    func updateUIFromRealmData()
}
protocol FetchCommonDataModelOutput {
    var fetchCommonDataModelObservable: Observable<[OtokuDataModel]> { get }
}
protocol FetchCommonDataModelType {
    var input: FetchCommonDataModelInput { get }
    var output: FetchCommonDataModelOutput { get }
}
// MARK: -
final class FetchCommonDataModel {
    private let calendarModel = BehaviorRelay<[OtokuDataModel]>(value: [])
    private var isUIUpdated = false
    private let dataFetcher: DataFetcher
    private let dataStorage: DataStorage
    private var versionManager: VersionManager
    
    init(dataFetcher: DataFetcher, dataStorage: DataStorage, versionManager: VersionManager) {
        self.dataFetcher = dataFetcher
        self.dataStorage = dataStorage
        self.versionManager = versionManager
    }
}
//MARK: - CalendarModel Extension
extension FetchCommonDataModel:FetchCommonDataModelInput{
    func bindFetchData() {
        if dataStorage.isEmpty() {
            fetchDataFromFirebaseAndUpdate()
        } else {
            dataFetcher.fetchVersion { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let currentVersion):
                    if self.versionManager.storedVersion ?? 0 < currentVersion {
                        self.fetchDataFromFirebaseAndUpdate()
                    } else if !self.isUIUpdated {
                        self.updateUIFromRealmData()
                    }
                case .failure:
                    // タイムアウト時の処理
                    DispatchQueue.global().asyncAfter(deadline: .now() + Constants.timeoutSeconds) {
                        if !(self.isUIUpdated) {
                            self.updateUIFromRealmData()
                        }
                    }
                }
            }
        }
    }
    func fetchDataFromFirebaseAndUpdate() {
        DispatchQueue.global().async {
            let ref = Database.database().reference().child("OtokuDataModelsObject")
            ref.observeSingleEvent(of: .value) { [weak self] snapshot in
                guard let self = self else {
                    print("Self has been deallocated.")
                    return
                }
                guard let otokuData = snapshot.value as? [Any] else {
                    print("Error retrieving otoku data from Firebase.")
                    return
                }
                self.dataStorage.saveData(otokuData) { result in
                    switch result {
                    case .success:
                        print("Data saved successfully.")
                    case .failure(let error):
                        print("Error saving data: \(error.localizedDescription)")
                    }
                }
                let versionRef = Database.database().reference().child(Constants.versionKey)
                versionRef.observeSingleEvent(of: .value) { snapshot in
                    guard let currentVersion = snapshot.value as? Int else {
                        print("Error retrieving current version from Firebase.")
                        return
                    }
                    self.versionManager.storedVersion = currentVersion
                    DispatchQueue.main.async {
                        self.updateUIFromRealmData()
                    }
                }
            }
        }
    }
    
    func updateUIFromRealmData() {
        let otokuDataList = dataStorage.retrieveData() as? [OtokuDataModel] ?? []
        DispatchQueue.main.async { // メインスレッドでのUIの更新
            self.calendarModel.accept(otokuDataList)
            self.isUIUpdated = true
        }
    }
}
extension FetchCommonDataModel: FetchCommonDataModelOutput {
    var fetchCommonDataModelObservable: Observable<[OtokuDataModel]> {
        return calendarModel.asObservable().share(replay: 1)
    }
}
extension FetchCommonDataModel: FetchCommonDataModelType {
    var input: FetchCommonDataModelInput { return self }
    var output: FetchCommonDataModelOutput { return self }
}
//Realm用model
@objcMembers class OtokuDataRealmModel: Object {
    dynamic var id = UUID().uuidString // プライマリキーを追加
    var address_ids = List<String>()
    dynamic var article_title = ""
    dynamic var blog_web_url = ""
    dynamic var collectionView_image_url = ""
    var enabled_dates = List<String>()
    override static func primaryKey() -> String? { // プライマリキーを設定
        return "id"
    }
    static func from(dictionary: [String: Any]) -> OtokuDataRealmModel? {
        let otokuDataModel = OtokuDataRealmModel()
        otokuDataModel.address_ids.append(objectsIn: dictionary["address_ids"] as? [String] ?? [])
        otokuDataModel.article_title = dictionary["article_title"] as? String ?? ""
        otokuDataModel.blog_web_url = dictionary["blog_web_url"] as? String ?? ""
        otokuDataModel.collectionView_image_url = dictionary["collectionView_image_url"] as? String ?? ""
        otokuDataModel.enabled_dates.append(objectsIn: dictionary["enabled_dates"] as? [String] ?? [])
        return otokuDataModel
    }
}
extension OtokuDataModel {
    func toDictionary() -> [String: Any] {
        return [
            "address_ids": self.address_ids,
            "article_title": self.article_title,
            "blog_web_url": self.blog_web_url,
            "collectionView_image_url": self.collectionView_image_url,
            "enabled_dates": self.enabled_dates
        ]
    }
}
