//
//  DBContentPrintDisplayModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2023/02/06.
//

import Foundation


class  DBContentPrintDisplayModel{

    // MARK: -　RealTimeDataBase保存用Print系
    func OtokuAddressModelsEncodeOk(check: Int, data: [OtokuAddressModel]) {//⭐️DBレジスターへ
        if check == 1{
            var modelBox:[Data] = []
            for i in data{
                if let content = i.content,let latitude = i.latitude,let longitude = i.longitude{
                    let model = OtokuAddressModel(address_id: i.address_id, content: content, latitude: latitude, longitude: longitude)
                    let encoder = JSONEncoder()
                    // フォーマットを指定
                    encoder.outputFormatting = .prettyPrinted
                    let jsonData = try? encoder.encode(model)
                    //                    print(String(data: jsonData! , encoding: .utf8)! + ",")
                    modelBox.append(jsonData!)
                }
            }
        }
    }
    func OtokuDataModelsEncodeOk(check: Int, data: [OtokuDataModel]) {//⭐️DBレジスターへ
        if check == 1{
            var dataBox:[Data] = []
            for i in data{
                let otokuDataModel = OtokuDataModel(address_ids: i.address_ids, article_title: i.article_title, blog_web_url: i.blog_web_url, collectionView_image_url: i.collectionView_image_url, enabled_dates: i.enabled_dates)
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let jsonData = try? encoder.encode(otokuDataModel)
                //                print(String(data: jsonData! , encoding: .utf8)! + ",")
                dataBox.append(jsonData!)
            }
        }
    }

    func decode(check: Int, data: [String]) {
        if check == 1{
            let decoder = JSONDecoder()
            for i in data{
                let jsonData = String(i).data(using: .utf8)!
                let test = try! decoder.decode(OtokuAddressModel.self, from: jsonData)
            }
        }
    }



}
