//
//  OtokuDataRealmModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2023/12/23.
//
import RealmSwift
// Realm用のカスタムモデルクラス。RealmのObjectクラスを継承。
@objcMembers class OtokuDataRealmModel: Object {
    // データの一意識別子。UUIDを用いて自動生成される。
    dynamic var id = UUID().uuidString
    // 記事に関連付けられたアドレスIDのリスト。リレーションシップを表す。
    var address_ids = List<String>()
    // 記事のタイトルを保存するためのプロパティ。
    dynamic var article_title = ""
    // 記事のブログURLを保存するためのプロパティ。
    dynamic var blog_web_url = ""
    // コレクションビューで表示する画像のURLを保存するためのプロパティ。
    dynamic var collectionView_image_url = ""
    // 有効な日付のリストを保存するためのプロパティ。特定の日付に関連する記事を識別するのに使用。
    var enabled_dates = List<String>()
        // Realmデータベース内でのプライマリキーを定義。ここでは'id'プロパティが使われる。
    override static func primaryKey() -> String? {
        return "id"
    }
    // 辞書型からOtokuDataRealmModelオブジェクトを作成するためのメソッド。
    // これにより、APIなどから取得したデータをRealm用のオブジェクトに変換できる。
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
