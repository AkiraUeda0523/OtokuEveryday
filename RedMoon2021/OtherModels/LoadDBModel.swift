//
//  LoadDBModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2021/12/07.
//

import Foundation
import Firebase


protocol GetSpecialtyDataProtocol{
    func GetSpecialtyData(array:[SlideShowModel])
}

class LoadDBModel{

    let db = Firestore.firestore()
    var slideArray = [SlideShowModel]()
    var getSpecialtyDataProtocol:GetSpecialtyDataProtocol?

    func fetchOtokuSpecialtyData(){
        Firestore.firestore().collection("OtokuSpecialtyData"
        ).document("2021").collection("2021-12").addSnapshotListener{ [self] snapshots, error in
            if let error = error {
                print("情報の取得に失敗\(error)")
                return
            }
            self.slideArray = []
            snapshots?.documents.forEach({ (snapshot) in
                let data = snapshot.data()
                if let information = SlideShowModel(input: data) {
                    self.slideArray.append(information)
                }
            })
            self.getSpecialtyDataProtocol?.GetSpecialtyData(array: self.slideArray)
        }
    }
}
