//
//  RealmStorageModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2023/12/23.
//
import RealmSwift
enum DataStorageError: Error {
    case failedToConvertData
}
// MARK: - Protocols
protocol RealmStorage {
    func saveToRealm(_ data: [OtokuDataModel])  throws
    func formatOtokuDataFromRealm()  -> [OtokuDataModel]
    func realmObjectsIsEmpty()  -> Bool
}
// MARK: - Main Class
class RealmStorageModel: RealmStorage {
    //レルムに新しいFireBaseのデータを上書き
    func saveToRealm(_ data: [OtokuDataModel])  throws {
        // Realmインスタンスの取得
        let realm = try  Realm()
        // Realmのトランザクションを開始
        try realm.write {
            // 既存データの削除
            let existingData = realm.objects(OtokuDataRealmModel.self)
            realm.delete(existingData)
            // 新しいデータの追加
            for otokuData in data {
                // モデルからRealmオブジェクトへの変換
                guard let otokuRealmModel = OtokuDataRealmModel.from(dictionary: otokuData.toDictionary()) else {
                    throw DataStorageError.failedToConvertData
                }
                realm.add(otokuRealmModel)
            }
        }
    }
    //レルムデータをOtokuDataModelに変換して使える状態に
    func formatOtokuDataFromRealm()  -> [OtokuDataModel] {
        do {
            // Realmインスタンスの取得
            let realm = try  Realm()
            // Realmからデータを取得し、モデル配列に変換
            let otokuDataBox = realm.objects(OtokuDataRealmModel.self)
            return Array(otokuDataBox.map(OtokuDataModel.from))
        } catch {
            // エラー時の処理（ログ出力等）
            print("Error initializing Realm: \(error.localizedDescription)")
            return []
        }
    }
    //レルムデータの有無の確認
    func realmObjectsIsEmpty()  -> Bool {
        do {
            // Realmインスタンスの取得
            let realm = try  Realm()
            // Realmデータベースが空かどうかを確認
            return realm.objects(OtokuDataRealmModel.self).isEmpty
        } catch {
            // エラー時の処理
            print("Error initializing Realm: \(error.localizedDescription)")
            return true
        }
    }
}
// MARK: -
extension OtokuDataModel {
    //レルムに保存用にデータを変換
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
