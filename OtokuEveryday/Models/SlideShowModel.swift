//
//  SlideShowModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2021/12/06.
//

import Foundation

struct SlideShowModel {
    var image:String
    var webUrl:String
    var title:String
    var address:String
    var comment:String
    init?(input: [String: Any]) {
        guard let webUrl = input["webUrl"] as? String,
              let address = input["address"] as? String,
              let title = input["title"] as? String,
              let image = input["image"] as? String,
              let comment = input["comment"] as? String
        else {
            return nil
        }
        self.webUrl = webUrl
        self.address = address
        self.title = title
        self.image = image
        self.comment = comment
    }
}
