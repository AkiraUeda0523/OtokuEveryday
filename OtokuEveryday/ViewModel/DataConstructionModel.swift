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


protocol EncodeDelegate {
    func OtokuAddressModelsEncodeOk(check:Int,data:[OtokuAddressModel])
    func OtokuDataModelsEncodeOk(check:Int,data:[OtokuDataModel])
    func decode(check:Int,data:Any)
}

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
}

struct OtokuAddressModel: Equatable ,Codable{
    let address_id:String
    let content:String?
    let latitude:Double?
    let longitude:Double?
}
// MARK: -
final class DataConstructionModel {
    var encodeDelegate:EncodeDelegate?
    var databaseRef: DatabaseReference!
    var array:[String] = []
//    var otokuDataBox:[OtokuDataModel] = []
//    var otokuAddressBox:[OtokuAddressModel] = []
  //⭐️  -------------------------------------------------------------
    //    外部公開用1
    var article: Observable<[OtokuDataModel]> {
        articlesRelay.asObservable()
    }
    //    外部公開用2
    var address: Observable<[OtokuAddressModel]> {
        addressRelay.asObservable()
    }
    //    上流のバケツ1
     let articlesRelay = BehaviorRelay<[OtokuDataModel]>(value: [])
    //    上流のバケツ2
     let addressRelay = BehaviorRelay<[OtokuAddressModel]>(value: [])
    //MARK: -
    //    上流のバケツ3
    private let selectDateRelay = BehaviorRelay<String>(value: "")
    //    外部公開用3
    var showableInfos: Observable<[OtokuDataModel]> {
        Observable.combineLatest(selectDateRelay,articlesRelay)
            .map { selectDate, data in
                data.filter {
                    $0.enabled_dates.contains(selectDate)
                }
            }
    }

    func selectDate(_ date: String) {
        selectDateRelay.accept(date)
    }
//    //MARK: -
//    //  全て情報データ
//    func fetchAllOtokuData(){
//        Firestore.firestore().collection("otoku_data").addSnapshotListener { snapShot, error in
//            self.otokuDataBox = []
//            if let snapShotDoc = snapShot?.documents{
//                for doc in snapShotDoc{
//                    let data = doc.data()
//                    if let addressIds = data["address_ids"],let articleTitle = data["article_title"],let blogWebUrl = data["blog_web_url"],let collectionViewImageUrl = data["collectionView_image_url"],let enabledDates = data["enabled_dates"]{
//                        let otokuDataModel = OtokuDataModel(address_ids: addressIds as! [String], article_title: articleTitle as! String, blog_web_url: blogWebUrl as! String, collectionView_image_url: collectionViewImageUrl as! String, enabled_dates: enabledDates as! [String])
//                        self.otokuDataBox.append(otokuDataModel)//"address_ids"自体がnilだとカレンダーのcollectionViewにも反映されない(空はおk)⚠️
//                    }
//                }
//                self.articlesRelay.accept(self.otokuDataBox)
//                self.encodeDelegate?.OtokuDataModelsEncodeOk(check: 1, data:self.otokuDataBox)
//            }
//        }
//    }
//    //  全て住所データ
//    func fetchAddressData(){
//        Firestore.firestore().collection("map_ addresses").addSnapshotListener { snapShot, error in
//            self.otokuAddressBox = []
//            if let snapShotDoc = snapShot?.documents{
//                for doc in snapShotDoc{
//                    let data = doc.data()
//                    if let content = data["content"] {
//                        let latitude = data["latitude"] as? Double
//                        let longitude = data["longitude"] as? Double
//                        let otokuAddressModel = OtokuAddressModel(address_id:doc.documentID, content: content as? String, latitude: latitude,longitude: longitude)
//                        self.otokuAddressBox.append(otokuAddressModel)
//                    }
//                }
//                self.addressRelay.accept(self.otokuAddressBox)
//                self.encodeDelegate?.OtokuAddressModelsEncodeOk(check: 1, data:self.otokuAddressBox)
//            }
//        }
//    }
//    //MARK: -
//    //  全て住所データ
//    func fetchAddressDataFromRealTimeDB(){
//        let ref = Database.database().reference()
//        ref.child("OtokuAddressModelsObject").observeSingleEvent(of: .value, with:{(snapshot) in
//            let data = snapshot.value as! [Any]
//            let addressData = data.map { (address) -> [String: Any] in
//                return address as! [String: Any]
//            }
//            for i in  addressData{
//                if let content = i["content"] ,
//                   let latitude = i["latitude"],
//                   let longitude = i["longitude"],
//                   let addressId = i["address_id"]{
//                    let otokuAddressModel = OtokuAddressModel(address_id: addressId as! String, content: content as! String, latitude: latitude as! Double,longitude: longitude as! Double)
//                    self.otokuAddressBox.append(otokuAddressModel)
//                }
//            }
//            self.addressRelay.accept(self.otokuAddressBox)
//            self.encodeDelegate?.decode(check: 1, data: data)
//        })
//    }
//    //  全て情報データ
//    func fetchAllOtokuDataFromRealTimeDB(){
//        let ref = Database.database().reference()
//        ref.child("OtokuDataModelsObject").observeSingleEvent(of: .value, with:{(snapshot) in
//            guard  let otokuData = snapshot.value as? [[String: Any]] else {return}
//            for i in  otokuData{
//                if let addressId = i["address_ids"] ,let articleTitle = i["article_title"],let blogWebUrl = i["blog_web_url"],let collectionViewImageUrl = i["collectionView_image_url"],let enabledDates = i["enabled_dates"]{
//                    let otokuDataModel = OtokuDataModel(address_ids: addressId as! [String], article_title: articleTitle as! String, blog_web_url: blogWebUrl as! String, collectionView_image_url: collectionViewImageUrl as! String, enabled_dates: enabledDates as! [String])
//                    self.otokuDataBox.append(otokuDataModel)
//                }
//            }
//            self.articlesRelay.accept(self.otokuDataBox)
//        })
//    }
    //MARK: -
    // combineLatestは最新同士で更新
    var mapTodaysModel:Observable<[OtokuMapModel]>{
        Observable.combineLatest(
            addressRelay,
            showableInfos
        )
        .map { address, info -> [OtokuMapModel] in
            info.flatMap { article -> [OtokuMapModel] in
                article.address_ids.compactMap {  id -> OtokuAddressModel? in
                    address.first(where: { $0.address_id == id })
                }
                .convertOtokuMapModel(article: article)
            }
        }
    }
    //MARK: -
    var mapModels:Observable<[OtokuMapModel]>{
        Observable.combineLatest(
            addressRelay,
            articlesRelay
        )
        .map { address, info -> [OtokuMapModel] in
            var result = [OtokuMapModel]()
            info.map { article -> [OtokuMapModel] in
                article.address_ids.compactMap {  id -> OtokuAddressModel? in
                    guard let address = address.first(where: { $0.address_id == id }) else {
                        return nil
                    }
                    return address
                }
                .map{  address -> OtokuMapModel in
                    OtokuMapModel(address: address, article_title: article.article_title, blog_web_url: article.blog_web_url, id: address.address_id)
                }
            }
            .forEach { models in
                models.forEach { model in
                    result.append(model)
                }
            }
            return result
        }
    }
    
}
//MARK: -
extension Array where Element == OtokuAddressModel {
    func convertOtokuMapModel(article: OtokuDataModel) -> [OtokuMapModel] {
        map { address in
            OtokuMapModel(
                address: address,
                article_title: article.article_title,
                blog_web_url: article.blog_web_url,
                id: address.address_id
            )
        }
    }
}
