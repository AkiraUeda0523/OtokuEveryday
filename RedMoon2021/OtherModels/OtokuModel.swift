//
//  OtokuModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2021/09/13.
//

import Foundation
import  Firebase
//imageをストレージへ
class OtokuModel {
    var image: String
    var webUrl: String
    var title: String
    var address: String
    var id: String
    init?(dic: [String: Any]) {
        guard let image = dic["image"] as? String,
              let webUrl = dic["webUrl"] as? String,
              let title = dic["title"] as? String,
              let address = dic["address"] as? String,
              let id = dic["id"] as? String
        else {
            return nil
        }
        self.image = image
        self.webUrl = webUrl
        self.title = title
        self.address = address
        self.id = id
    }
}
