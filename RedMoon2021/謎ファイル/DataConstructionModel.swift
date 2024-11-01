//
//  DataConstructionModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2022/04/10.
//

import Foundation
import RxSwift
import RxCocoa
import Firebase
import FirebaseFirestore
import FirebaseDatabase




struct OtokuMapModel: Codable,Equatable {
    internal init(address: OtokuAddressModel, article_title: String, blog_web_url: String, id: String) {
        self.address = address
        self.article_title = article_title
        self.blog_web_url = blog_web_url
        self.id = id
    }
    var address:OtokuAddressModel
    var article_title:String
    var blog_web_url:String
    var id:String
}
// MARK: -
struct  OtokuDataModel:Codable,Equatable{
    var address_ids:[String]
    var article_title:String
    var blog_web_url:String
    var collectionView_image_url:String
    var enabled_dates:[String]

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

struct OtokuAddressModel: Equatable ,Codable{
    let address_id:String
    let content:String?
    let latitude:Double?
    let longitude:Double?
}

////MARK: -
//extension Array where Element == OtokuAddressModel {
//    func convertOtokuMapModel(article: OtokuDataModel) -> [OtokuMapModel] {
//        map { address in
//            OtokuMapModel(
//                address: address,
//                article_title: article.article_title,
//                blog_web_url: article.blog_web_url,
//                id: address.address_id
//            )
//        }
//    }
//}
