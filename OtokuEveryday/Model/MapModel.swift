//
//  MapModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2023/02/07.
//

import RxSwift
import RxCocoa
import Firebase
import RealmSwift

protocol MapModelInput {
    func fetchAddressDataFromRealTimeDB()
    func fetchAllOtokuDataFromRealTimeDB()
    func fetchOtokuSpecialtyData()
}
protocol MapModelOutput {
    var AddressDataObservable: Observable<[OtokuAddressModel]> { get }
    var AllOtokuDataObservable: Observable<[OtokuDataModel]> { get }
    var otokuSpecialtyObservable: Observable<[SlideShowModel]> { get }
}
protocol MapModelType {
    var output: MapModelOutput { get }
    var input: MapModelInput { get }
}
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
//MARK: -
final class MapModel{
    private let addressDataRelay = BehaviorRelay<[OtokuAddressModel]>(value: [])
    private let otokuDataRelay = BehaviorRelay<[OtokuDataModel]>(value: [])
    private let otokuSpecialtyRelay = BehaviorRelay<[SlideShowModel]>(value: [])
}
//MARK: -extension　Input
extension MapModel:MapModelInput{
    
    func fetchAddressDataFromRealTimeDB() {
        let realm = try! Realm()
        let otokuAddressBox = realm.objects(OtokuAddressRealmModel.self)
        if !otokuAddressBox.isEmpty {
            self.addressDataRelay.accept(otokuAddressBox.map { $0.toModel() })
        } else {
            let ref = Database.database().reference()
            ref.child("OtokuAddressModelsObject").observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
                guard let strongSelf = self else { return }
                guard let data = snapshot.value as? [Any] else { return }
                var otokuAddressBox: [OtokuAddressModel] = []
                for element in data {
                    // Check if the element is NSNull
                    if element is NSNull { continue }
                    // Cast the element as [String: Any]
                    guard let i = element as? [String: Any] else { continue }
                    if let content = i["content"] as? String,
                       let latitude = i["latitude"] as? Double,
                       let longitude = i["longitude"] as? Double,
                       let addressId = i["address_id"] as? String {
                        let otokuAddressModel = OtokuAddressModel(address_id: addressId, content: content, latitude: latitude, longitude: longitude)
                        otokuAddressBox.append(otokuAddressModel)
                        let realmModel = OtokuAddressRealmModel.from(otokuAddressModel)
                        try! realm.write {
                            realm.add(realmModel, update: .modified)
                        }
                    }
                }
                strongSelf.addressDataRelay.accept(otokuAddressBox)
            })
        }
    }
    //  全て情報データ
    func fetchAllOtokuDataFromRealTimeDB(){
        var otokuDataBox:[OtokuDataModel] = []
        let ref = Database.database().reference()
        ref.child("OtokuDataModelsObject").observeSingleEvent(of: .value, with:{(snapshot) in
            guard let otokuData = snapshot.value as? [Any] else { return } // Cast snapshot value as [Any]
            for element in  otokuData{
                if element is NSNull { continue }
                guard let i = element as? [String: Any] else { continue }
                
                if let addressId = i["address_ids"] ,let articleTitle = i["article_title"],let blogWebUrl = i["blog_web_url"],let collectionViewImageUrl = i["collectionView_image_url"],let enabledDates = i["enabled_dates"]{
                    let otokuDataModel = OtokuDataModel(address_ids: addressId as! [String], article_title: articleTitle as! String, blog_web_url: blogWebUrl as! String, collectionView_image_url: collectionViewImageUrl as! String, enabled_dates: enabledDates as! [String])
                    otokuDataBox.append(otokuDataModel)
                }
            }
            self.otokuDataRelay.accept(otokuDataBox)
        })
    }
    //オススメデータ
    func fetchOtokuSpecialtyData(){
        var slideArray = [SlideShowModel]()
        Firestore.firestore().collection("OtokuSpecialtyData"
        ).document("2021").collection("2021-12").addSnapshotListener{ [self] snapshots, error in
            if let error = error {
                print("情報の取得に失敗\(error)")
                return
            }
            slideArray = []
            snapshots?.documents.forEach({ (snapshot) in
                let data = snapshot.data()
                if let information = SlideShowModel(input: data) {
                    slideArray.append(information)
                }
            })
            self.otokuSpecialtyRelay.accept(slideArray)
        }
    }
}
//MARK: -extension　Output
extension MapModel:MapModelOutput{
    var otokuSpecialtyObservable: Observable<[SlideShowModel]> {
        return otokuSpecialtyRelay.asObservable()
    }
    var AddressDataObservable: Observable<[OtokuAddressModel]> {
        return addressDataRelay.asObservable()
    }
    var AllOtokuDataObservable: Observable<[OtokuDataModel]> {
        return  otokuDataRelay.asObservable()
    }
}
//MARK: -extension　Type
extension MapModel: MapModelType {
    var output: MapModelOutput { return self }
    var input: MapModelInput { return self }
}
@objcMembers class OtokuAddressRealmModel: Object {
    dynamic var address_id: String = ""
    dynamic var content: String = ""
    dynamic var latitude: Double = 0.0
    dynamic var longitude: Double = 0.0
    override static func primaryKey() -> String? {
        return "address_id"
    }
    static func from(_ model: OtokuAddressModel) -> OtokuAddressRealmModel {
        let realmModel = OtokuAddressRealmModel()
        realmModel.address_id = model.address_id
        realmModel.content = model.content!
        realmModel.latitude = model.latitude!
        realmModel.longitude = model.longitude!
        return realmModel
    }
    func toModel() -> OtokuAddressModel {
        return OtokuAddressModel(address_id: address_id, content: content, latitude: latitude, longitude: longitude)
    }
}
