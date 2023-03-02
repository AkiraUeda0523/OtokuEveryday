//
//  MapModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2023/02/07.
//

import Foundation
import RxSwift
import Firebase


class MapModel{
    //MARK: -
    //  全て住所データ
    func fetchAddressDataFromRealTimeDB(dataConstructionModel:DataConstructionModel){

        var otokuAddressBox:[OtokuAddressModel] = []
        let ref = Database.database().reference()
        ref.child("OtokuAddressModelsObject").observeSingleEvent(of: .value, with:{(snapshot) in
            let data = snapshot.value as! [Any]
            let addressData = data.map { (address) -> [String: Any] in
                return address as! [String: Any]
            }
            for i in  addressData{
                if let content = i["content"] ,
                   let latitude = i["latitude"],
                   let longitude = i["longitude"],
                   let addressId = i["address_id"]{
                    let otokuAddressModel = OtokuAddressModel(address_id: addressId as! String, content: content as! String, latitude: latitude as! Double,longitude: longitude as! Double)
                   otokuAddressBox.append(otokuAddressModel)
                }
            }
            dataConstructionModel.addressRelay.accept(otokuAddressBox)
    //             self.encodeDelegate?.decode(check: 1, data: data)
        })
    }
    //  全て情報データ
    func fetchAllOtokuDataFromRealTimeDB(dataConstructionModel:DataConstructionModel){
        var otokuDataBox:[OtokuDataModel] = []
        let ref = Database.database().reference()
        ref.child("OtokuDataModelsObject").observeSingleEvent(of: .value, with:{(snapshot) in
            guard  let otokuData = snapshot.value as? [[String: Any]] else {return}
            for i in  otokuData{
                if let addressId = i["address_ids"] ,let articleTitle = i["article_title"],let blogWebUrl = i["blog_web_url"],let collectionViewImageUrl = i["collectionView_image_url"],let enabledDates = i["enabled_dates"]{
                    let otokuDataModel = OtokuDataModel(address_ids: addressId as! [String], article_title: articleTitle as! String, blog_web_url: blogWebUrl as! String, collectionView_image_url: collectionViewImageUrl as! String, enabled_dates: enabledDates as! [String])
                otokuDataBox.append(otokuDataModel)
                }
            }
            dataConstructionModel.articlesRelay.accept(otokuDataBox)
        })
    }

}




