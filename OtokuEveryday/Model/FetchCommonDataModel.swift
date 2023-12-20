//
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

enum FirebaseFetcherError: Error {
    case invalidVersionData
    case invalidOtokuData
}

enum DataStorageError: Error {
    case failedToConvertData
}

protocol DataFetcher {
    func fetchVersion() async throws -> Int
    func fetchData() async throws -> [OtokuDataModel]
}

protocol DataStorage {
    func saveData(_ data: [OtokuDataModel]) async throws
    func retrieveData() async -> [OtokuDataModel]
    func isEmpty() async throws -> Bool
}

protocol VersionManager {
    var storedVersion: Int? { get set }
}

protocol DatabaseReferenceProtocol {
    func observeSingleEvent(of eventType: DataEventType, with block: @escaping (DataSnapshot) -> Void)
}

class FirebaseFetcher: DataFetcher {
    func fetchVersion() async throws -> Int {
        let versionRef = Database.database().reference().child(Constants.versionKey)
        let snapshot = try await versionRef.getData()
        guard let version = snapshot.value as? Int else {
            throw FirebaseFetcherError.invalidVersionData
        }
        return version
    }
    func fetchData() async throws -> [OtokuDataModel] {
        let ref = Database.database().reference().child("OtokuDataModelsObject")
        let snapshot = try await ref.getData()
        guard let dataDictionaries = snapshot.value as? [[String: Any]] else {
            throw FirebaseFetcherError.invalidOtokuData
        }
        let jsonData = try JSONSerialization.data(withJSONObject: dataDictionaries, options: [])
        let otokuDataModels = try JSONDecoder().decode([OtokuDataModel].self, from: jsonData)
        return otokuDataModels
    }
}
class RealmStorage: DataStorage {
    @MainActor
    func saveData(_ data: [OtokuDataModel]) async throws {
        let realm = try await Realm()
        try realm.write {
            let existingData = realm.objects(OtokuDataRealmModel.self)
            realm.delete(existingData)
            for otokuData in data {
                guard let otokuRealmModel = OtokuDataRealmModel.from(dictionary: otokuData.toDictionary()) else {
                    throw DataStorageError.failedToConvertData
                }
                realm.add(otokuRealmModel)
            }
        }
    }
    @MainActor
    func retrieveData() async -> [OtokuDataModel] {
        do {
            let realm = try await Realm()
            let otokuDataBox = realm.objects(OtokuDataRealmModel.self)
            return Array(otokuDataBox.map(OtokuDataModel.from))
        } catch {
            print("Error initializing Realm: \(error.localizedDescription)")
            return []
        }
    }
    @MainActor
    func isEmpty() async -> Bool {
        do {
            let realm = try await Realm()
            return realm.objects(OtokuDataRealmModel.self).isEmpty
        } catch {
            print("Error initializing Realm: \(error.localizedDescription)")
            return true
        }
    }
}
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
    func bindFetchData() async
    func updateUIFromRealmData() async
}
protocol FetchCommonDataModelOutput {
    var fetchCommonDataModelObservable: Observable<[OtokuDataModel]> { get }
    var shouldUpdateDataObservable: Observable<Bool> { get }
}
protocol FetchCommonDataModelType {
    var input: FetchCommonDataModelInput { get }
    var output: FetchCommonDataModelOutput { get }
}
// MARK: -
final class FetchCommonDataModel {
    private let otokuDataModelRelay = BehaviorRelay<[OtokuDataModel]>(value: [])
    private var isUIUpdated = false
    private let dataFetcher: DataFetcher
    private let dataStorage: DataStorage
    private var versionManager: VersionManager
    private let disposeBag = DisposeBag()
    private let shouldUpdateData = PublishSubject<Bool>()
    
    init(dataFetcher: DataFetcher, dataStorage: DataStorage, versionManager: VersionManager) {
        self.dataFetcher = dataFetcher
        self.dataStorage = dataStorage
        self.versionManager = versionManager
    }
}
//MARK: - CalendarModel Extension
extension FetchCommonDataModel:FetchCommonDataModelInput{
    @MainActor
    func bindFetchData() async {
        do {
            if try await dataStorage.isEmpty() {
                await fetchDataFromFirebaseAndUpdate()
                return
            }
            
            let currentVersion = try await dataFetcher.fetchVersion()
            await handleVersionFetched(currentVersion: currentVersion)
        } catch {
            await updateUIFromRealmData()
        }
    }
    @MainActor
    private func handleNetworkConnected() async {
        do {
            // データストレージが空かどうかを非同期でチェックします
            if try await dataStorage.isEmpty() {
                await fetchDataFromFirebaseAndUpdate()
                return
            }
            // データフェッチャーからバージョンを非同期で取得します
            let currentVersion = try await dataFetcher.fetchVersion()
            await handleVersionFetched(currentVersion: currentVersion)
        } catch {
            // エラーが発生した場合、ローカルデータを使用してUIを更新します
            await updateUIFromRealmData()
        }
    }
    @MainActor
    private func handleVersionFetched(currentVersion: Int) async {
        guard let storedVersion = versionManager.storedVersion else {
            await updateUIFromRealmData()
            return
        }
        
        if storedVersion < currentVersion {
            await fetchDataFromFirebaseAndUpdate()
            shouldUpdateData.onNext(true)
        } else {
            await updateUIFromRealmData()
            shouldUpdateData.onNext(false)
            
        }
    }
    func isConnectedToNetwork() async -> Bool {
        await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "NetworkMonitor")
            monitor.pathUpdateHandler = { path in
                continuation.resume(returning: path.status == .satisfied)
                monitor.cancel()
            }
            monitor.start(queue: queue)
        }
    }
    func fetchDataFromFirebaseAndUpdate() async {
        do {
            let otokuData = try await dataFetcher.fetchData()
            try await dataStorage.saveData(otokuData)
            print("Data saved successfully.")
            await fetchVersionAndUpdateUI()
        } catch {
            print("Error retrieving otoku data from Firebase: \(error)")
        }
    }
    // バージョン情報をフェッチし、UIを更新します。
    private func fetchVersionAndUpdateUI() async {
        do {
            let currentVersion = try await dataFetcher.fetchVersion()
            versionManager.storedVersion = currentVersion
            await updateUIFromRealmData()
        } catch {
            print("Error retrieving version from Firebase: \(error)")
            await updateUIFromRealmData()
        }
    }
    
    @MainActor
    func updateUIFromRealmData() async {
        let otokuDataList = await dataStorage.retrieveData()
        
        self.otokuDataModelRelay.accept(otokuDataList)
        self.isUIUpdated = true
    }
}
extension FetchCommonDataModel: FetchCommonDataModelOutput {
    var shouldUpdateDataObservable: RxSwift.Observable<Bool> {
        shouldUpdateData.asObservable()
    }
    var fetchCommonDataModelObservable: Observable<[OtokuDataModel]> {
        return otokuDataModelRelay.asObservable().share(replay: 1)/
    }
}
extension FetchCommonDataModel: FetchCommonDataModelType {
    var input: FetchCommonDataModelInput { return self }
    var output: FetchCommonDataModelOutput { return self }
}
//Realm用model
@objcMembers class OtokuDataRealmModel: Object {
    dynamic var id = UUID().uuidString
    var address_ids = List<String>()
    dynamic var article_title = ""
    dynamic var blog_web_url = ""
    dynamic var collectionView_image_url = ""
    var enabled_dates = List<String>()
    override static func primaryKey() -> String? {
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
