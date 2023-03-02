//
//  DBRegisterModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2022/09/08.
//

import Foundation
import Firebase
import FirebaseFirestore

struct  getAddressModel{
    var name:String
    var addressID:String
}

class DBRegisterModel{
    
    let  shopName = "三田製麺所"
    
    let otoku_dataID = "YxKFB3hhe7QrNSb9Rgb0"
    
    
    private let db = Firestore.firestore()
    // MARK: -
    func fetchFireStoreAddressToRealtimeDatabase(){
        var addressBox:[OtokuAddressModel] = []
        let hobbyParams = ["味の時計台","丼丼亭","肉劇場","三田製麺所"]

        for i in hobbyParams{

            Firestore.firestore().collection("map_ addresses")
                .whereField("name", isEqualTo: i)
                .addSnapshotListener { querySnapshot, error in
                    guard let snapshot = querySnapshot else {
                        print("Error retreiving snapshots \(error!)")
                        return
                    }
                    let snapShotDoc = snapshot.documents

                    for doc in snapShotDoc{
                        let data = doc.data()
                        let NewContent = OtokuAddressModel(address_id: doc.documentID, content: data["content"] as? String, latitude: data["latitude"] as? Double, longitude: data["longitude"] as? Double)
                        addressBox.append(NewContent)
                    }
                    let encoder = JSONEncoder()
                    // フォーマットを指定
                    encoder.outputFormatting = .prettyPrinted
                    // エンコード
                    let jsonData = try? encoder.encode(addressBox)
                    print("AddressToRealtimeDatabase",String(data: jsonData! , encoding: .utf8)! + ",")
                }
        }
    }
    // MARK: -
    func fetchFireStoreDataToRealtimeDatabase(){
        var dataBox:[OtokuDataModel] = []
        let hobbyParams = ["味の時計台","丼丼亭","肉劇場","三田製麺所"]

        for i in hobbyParams{
            Firestore.firestore().collection("otoku_data")
                .whereField("name", isEqualTo: i)
                .addSnapshotListener { querySnapshot, error in
                    guard let snapshot = querySnapshot else {
                        print("Error retreiving snapshots \(error!)")
                        return
                    }
                    let snapShotDoc = snapshot.documents

                    for doc in snapShotDoc{
                        let data = doc.data()
                        let NewData = OtokuDataModel(address_ids: data["address_ids"] as! [String], article_title: data["article_title"] as! String, blog_web_url: data["blog_web_url"] as! String, collectionView_image_url: data["collectionView_image_url"] as! String, enabled_dates: data["enabled_dates"] as! [String])
                        dataBox.append(NewData)
                    }
                    let encoder = JSONEncoder()
                    // フォーマットを指定
                    encoder.outputFormatting = .prettyPrinted
                    // エンコード
                    let jsonData = try? encoder.encode(dataBox)
                    print("DataToRealtimeDatabase",String(data: jsonData! , encoding: .utf8)! + ",")
                }
        }
    }
    // MARK: -
    func registarContent(){
        let content = ["    東京都港区芝5-22-8 アトラス田町ビル    ",
                       "    東京都渋谷区恵比寿南2-1-12 サトウビル1F    "]
        for i in content{
            
            db.collection("map_ addresses")
                .document()
                .setData(
                    [
                        "content": i,
                        "name": shopName,
                        "createdDate": Timestamp()
                    ]
                ) }
    }
    // MARK: -
    func regestarDocumentID(){//二発入る現象は何故⚠️fb更新時（ジオ取れた時）に倍々になってる　　グローバルのボックスが原因か！　※fb更新時メソッドも実行
        var box:[String] = []

        Firestore.firestore().collection("map_ addresses").addSnapshotListener { [self] snapShot, error in
            if let snapShotDoc = snapShot?.documents{
                for doc in snapShotDoc{
                    let data = doc.data()
                    if let name = data["name"] as? String{
                        let getadress = getAddressModel(name: name, addressID: doc.documentID)
                        if getadress.name == shopName{
                            box.append(getadress.addressID)
                        }
                    }
                }
            }
            
            let data: [String: Any] = [
                "address_ids": box
                ,
                "name":shopName
                ,
                "createdDate": Timestamp()
            ]
            db.collection("otoku_data").document(otoku_dataID).setData(data,merge: true
            ) { err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    print("Document successfully written!")
                }
            }
        }
    }
    // MARK: -
    func errorID(){//⚠️⚠️⚠️手入力の際は文字列ではなくIntに変更必須‼️
        var box:[String] = []

        Firestore.firestore().collection("map_ addresses").addSnapshotListener { snapShot, error in
            
            if let snapShotDoc = snapShot?.documents{
                for doc in snapShotDoc{
                    let data = doc.data()
                    if (data["latitude"] == nil) {
                        let data2 = doc.documentID
                        box.append(data2)
                    }
                }
            }
        }
    }
    // MARK: -
    func notErrorID(){
        var box:[String] = []

        Firestore.firestore().collection("map_ addresses").addSnapshotListener { snapShot, error in

            if let snapShotDoc = snapShot?.documents{
                for doc in snapShotDoc{
                    let data = doc.data()
                    if (data["latitude"] != nil && data["errorFlag"] != nil) {
                        let data2 = doc.documentID
                        box.append(data2)
                    }
                }
            }
        }
    }
    // MARK: -
    func  fetchError(){
        let id: [String] = ["DCN3RNQxauw1xJHaVwdL", "FHNddY2x4ZtLfLQl7eiW"]
        let data: [String: Bool] = [
            "errorFlag": true
        ]
        for i in id{
            db.collection("map_ addresses").document(i).setData(data,merge: true
            ) { err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    print("Document successfully written!")
                }
            }
        }
    }
    // MARK: -
    func delete(){
        let delete = ["1ZX5FcvNPsSarDGk6Qhy", "2dtEOqH0240JLrcbyEBP"]
        for i in delete {
            Firestore.firestore().collection("otoku_data").document(i).delete()
        }
    }
    // MARK: -
    func  changeFlagID(){
        let deleteFlagID:[String] = ["09KPHCGpUG79wsRio6x8", "0OF0r8Vz51GxpG7n7X6X"]
        let okData: [String: Bool] = [
            "errorFlag": false
        ]
        for i in deleteFlagID{
            db.collection("map_ addresses").document(i).setData(okData,merge: true
            ) { err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    print("Document successfully written!")
                }
            }
        }
    }
}
