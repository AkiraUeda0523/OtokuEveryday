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
import AlamofireImage
import Swinject

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
    private let imageCache = AutoPurgingImageCache()
    var retryCount = 0
    let maxRetryCount = 3
}
//MARK: - CalendarModel Extension
extension FetchCommonDataModel:FetchCommonDataModelInput{
    //-----------------------------------------------------------------------４つの関数が繋がっている
    func bindFetchData() {
        let realm = try! Realm()
        let otokuDataBox = realm.objects(OtokuDataRealmModel.self)
        
        if otokuDataBox.isEmpty {
            fetchDataFromFirebaseAndUpdate()
        } else {
            let versionRef = Database.database().reference().child("version")
            // タイムアウト時間を設定
            let timeoutSeconds = 5.0
            DispatchQueue.global().asyncAfter(deadline: .now() + timeoutSeconds) { [weak self] in
                // タイムアウト時の処理
                if !(self?.isUIUpdated ?? false) {
                    self?.updateUIFromRealmData()
                }
            }
            versionRef.observeSingleEvent(of: .value) { [weak self] snapshot in
                guard let self = self else { return }
                if let currentVersion = snapshot.value as? Int,
                   let storedVersion = UserDefaults.standard.value(forKey: "storedVersion") as? Int,
                   storedVersion < currentVersion {
                    self.fetchDataFromFirebaseAndUpdate()
                } else if !self.isUIUpdated {
                    self.updateUIFromRealmData()
                }
            }
        }
    }
    
    func fetchDataFromFirebaseAndUpdate() {//エラーハンドリング
        DispatchQueue.global().async { // 新たなスレッドで実行
            let ref = Database.database().reference().child("OtokuDataModelsObject")
            ref.observeSingleEvent(of: .value) { [weak self] snapshot in
                guard let self = self, let otokuData = snapshot.value as? [Any] else { return }
                let realm = try! Realm()
                try! realm.write {
                    realm.delete(realm.objects(OtokuDataRealmModel.self))
                    var otokuDataModels = [OtokuDataRealmModel]()
                    for element in otokuData {
                        if element is NSNull { continue }
                        guard let i = element as? [String: Any] else { continue }
                        if let otokuDataModel = OtokuDataRealmModel.from(dictionary: i) {
                            otokuDataModels.append(otokuDataModel)
                        }
                    }
                    realm.add(otokuDataModels, update: .modified)
                }
                
                let versionRef = Database.database().reference().child("version")
                versionRef.observeSingleEvent(of: .value) { snapshot in
                    if let currentVersion = snapshot.value as? Int {
                        UserDefaults.standard.set(currentVersion, forKey: "storedVersion")
                    }
                    DispatchQueue.main.async { // メインスレッド
                        self.updateUIFromRealmData()
                    }
                }
            }
        }
    }
    
    func updateUIFromRealmData() {
        DispatchQueue.main.async { // メインスレッド
            let otokuDataList = self.mapOtokuDataFromRealm()
            self.calendarModel.accept(otokuDataList)
            self.isUIUpdated = true
        }
    }
    private func mapOtokuDataFromRealm() -> [OtokuDataModel] {
        let realm = try! Realm()
        let otokuDataBox = realm.objects(OtokuDataRealmModel.self)
        return otokuDataBox.map(OtokuDataModel.from)
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
//-------------------------------------------------------------------------------------Realm用model
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
