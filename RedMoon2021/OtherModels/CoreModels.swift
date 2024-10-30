//
//  CoreModels.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2022/04/10.
//
//
// MARK: - OtokuMapModel
struct OtokuMapModel: Codable, Equatable {
    var address: OtokuAddressModel
    var article_title: String
    var blog_web_url: String
    var id: String
}
// MARK: - OtokuDataModel
struct  OtokuDataModel: Codable, Equatable {
    var address_ids: [String]
    var article_title: String
    var blog_web_url: String
    var collectionView_image_url: String
    var enabled_dates: [String]
    static func from(_ otokuDataRealmModel: OtokuDataRealmModel) -> OtokuDataModel {
        return OtokuDataModel(
            address_ids: Array(otokuDataRealmModel.address_ids),
            article_title: otokuDataRealmModel.article_title,
            blog_web_url: otokuDataRealmModel.blog_web_url,
            collectionView_image_url: otokuDataRealmModel.collectionView_image_url,
            enabled_dates: Array(otokuDataRealmModel.enabled_dates)
        )
    }
}
// MARK: - OtokuAddressModel
struct OtokuAddressModel: Codable, Equatable {
    let address_id: String
    let content: String?
    var latitude: Double?
    var longitude: Double?
}
// MARK: -structのイメージ
//struct OtokuMapModel: Codable, Equatable {
    //    internal init(address: OtokuAddressModel, article_title: String, blog_web_url: String, id: String) {
    //        self.address = address
    //        self.article_title = article_title
    //        self.blog_web_url = blog_web_url
    //        self.id = id
    //    }自動生成される
//    var address: OtokuAddressModel
//    var article_title: String
//    var blog_web_url: String
//    var id: String
//}
