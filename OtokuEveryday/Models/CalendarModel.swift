//
//  CalendarModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2023/02/02.
//

import Foundation
import RxSwift
import Firebase
import RxCocoa

protocol CalendarModelInput {
    func fetchscrollTitle()
    func fetchAllOtokuDataFromRealTimeDB()
    func authState()
}
protocol CalendarModelOutput {
    var calendarModelObservable: Observable<[OtokuDataModel]> { get }
    var authHandleObserbable: Observable<AuthStateDidChangeListenerHandle> { get }
    var scrollTitleObservable: Observable<[ScrollModel]> { get }
}
protocol CalendarModelType {
    var output: CalendarModelOutput { get }
    var input: CalendarModelInput { get }
}
// MARK: -
final class CalendarModel {
    //output
    private let calendarModel = BehaviorRelay<[OtokuDataModel]>(value: [])
    private let authHandle = PublishRelay<AuthStateDidChangeListenerHandle>()
    private let scrollTitle = BehaviorRelay<[ScrollModel]>(value: [])
}
//MARK: - CalendarModel Extension
extension CalendarModel: CalendarModelType {
    var output: CalendarModelOutput { return self }
    var input: CalendarModelInput { return self }
}
extension CalendarModel:CalendarModelInput{
    //  全て情報データ
    func fetchAllOtokuDataFromRealTimeDB(){
        var otokuDataBox:[OtokuDataModel] = []
        let ref = Database.database().reference()
        ref.child("OtokuDataModelsObject").observeSingleEvent(of: .value, with:{(snapshot) in
            guard  let otokuData = snapshot.value as? [[String: Any]] else {return}
            for i in  otokuData{
                if let addressId = i["address_ids"] ,let articleTitle = i["article_title"],let blogWebUrl = i["blog_web_url"],let collectionViewImageUrl = i["collectionView_image_url"],let enabledDates = i["enabled_dates"]{
                    let otokuDataModel = OtokuDataModel(address_ids: addressId as! [String], article_title: articleTitle as! String, blog_web_url: blogWebUrl as! String, collectionView_image_url: collectionViewImageUrl as! String, enabled_dates: enabledDates as! [String])
                    otokuDataBox.append(otokuDataModel)
                    print("kakuninn",otokuDataBox)
                }
            }
            self.calendarModel.accept(otokuDataBox)
        })
    }
    //  匿名サインイン判定
    func authState(){
        var authHandle: AuthStateDidChangeListenerHandle!
        var retryCount = 0
        authHandle = Auth.auth().addStateDidChangeListener({  (auth, user) in//Model
            if  let currentUser = user{
                //もし、ユーザーが匿名で利用していたら
                if currentUser.isAnonymous {
                    //                   self.setUpLayout()//⭐️
                }
            }else if retryCount < 5 {
                retryCount += 1
                //匿名サインイン
                Auth.auth().signInAnonymously { (authResult, error) in
                    guard let user = authResult?.user, error == nil else {
                        print("匿名サインインに失敗しました:" ,error!.localizedDescription)
                        return
                    }
                    print("匿名サインインに成功しました", user.uid)
                }
            }
        })
        self.authHandle.accept(authHandle)
    }
    //scrollLabelに流す本日のお得記事タイトルの取得
    func fetchscrollTitle(){
        let today = GetDateModel.gatToday()//Model直
        var newScrollArray = [ScrollModel]()
        Firestore.firestore().collection("OtokuWebData").document("2021-2022").collection("Day\(today)").addSnapshotListener { snapshots, error in
            if let error = error {
                print("情報の取得に失敗\(error)")
                return
            }
            newScrollArray = []
            if let snapShotDoc = snapshots?.documents{
                for doc in snapShotDoc{
                    let data = doc.data()
                    if let scrolltitle = data["title"] as? String {
                        let scrollModel = ScrollModel(title: scrolltitle)
                        newScrollArray.append(scrollModel)
                    }
                }
                self.scrollTitle.accept(newScrollArray)
            }
        }
    }
}
extension CalendarModel:CalendarModelOutput{
    var calendarModelObservable: Observable<[OtokuDataModel]> {
        return calendarModel.asObservable()
    }
    var authHandleObserbable: Observable<AuthStateDidChangeListenerHandle> {
        return authHandle.asObservable()
    }
    var scrollTitleObservable: Observable<[ScrollModel]>{
        return scrollTitle.asObservable()
    }
}




////
////  CalendarModel.swift
////  RedMoon2021
////
////  Created by 上田晃 on 2023/02/02.
////
//
//import Foundation
//import RxSwift
//import Firebase
//import RxCocoa
//
//protocol CalendarModelInput {
//    func fetchscrollTitle()
//    func fetchAllOtokuDataFromRealTimeDB()
//    func authState()
//}
//protocol CalendarModelOutput {
//    var calendarModelObservable: Observable<[OtokuDataModel]> { get }
//    var authHandleObserbable: Observable<AuthStateDidChangeListenerHandle> { get }
//    var scrollTitleObservable: Observable<[ScrollModel]> { get }
//}
//protocol CalendarModelType {
//    var output: CalendarModelOutput { get }
//    var input: CalendarModelInput { get }//in,outがあるだけでMとみなすと言うこと
//}
//// MARK: -
//final class CalendarModel {
//    //output
//    private let calendarModel = BehaviorRelay<[OtokuDataModel]>(value: [])
//    private let authHandle = PublishRelay<AuthStateDidChangeListenerHandle>()
//    private let scrollTitle = BehaviorRelay<[ScrollModel]>(value: [])
//}
////MARK: - CalendarModel Extension
//extension CalendarModel: CalendarModelType {
//    var output: CalendarModelOutput { return self }
//    var input: CalendarModelInput { return self }
//}
//extension CalendarModel:CalendarModelInput{
//    //  全て情報データ
//    func fetchAllOtokuDataFromRealTimeDB(){
//        var otokuDataBox:[OtokuDataModel] = []
//        let ref = Database.database().reference()
//        ref.child("OtokuDataModelsObject").observeSingleEvent(of: .value, with:{(snapshot) in
//            guard  let otokuData = snapshot.value as? [[String: Any]] else {return}
//            for i in  otokuData{
//                if let addressId = i["address_ids"] ,let articleTitle = i["article_title"],let blogWebUrl = i["blog_web_url"],let collectionViewImageUrl = i["collectionView_image_url"],let enabledDates = i["enabled_dates"]{
//                    let otokuDataModel = OtokuDataModel(address_ids: addressId as! [String], article_title: articleTitle as! String, blog_web_url: blogWebUrl as! String, collectionView_image_url: collectionViewImageUrl as! String, enabled_dates: enabledDates as! [String])
//                    otokuDataBox.append(otokuDataModel)
//                    print("kakuninn",otokuDataBox)//Ouputでテスト可能
//                }
//            }
//            self.calendarModel.accept(otokuDataBox)
//        })
//    }
//    //  匿名サインイン判定
//    func authState(){
//        var authHandle: AuthStateDidChangeListenerHandle!
//        var retryCount = 0
//        authHandle = Auth.auth().addStateDidChangeListener({  (auth, user) in//Model
//            if  let currentUser = user{
//                //もし、ユーザーが匿名で利用していたら
//                if currentUser.isAnonymous {
//                    //                   self.setUpLayout()//⭐️
//                }
//            }else if retryCount < 5 {
//                retryCount += 1
//                //匿名サインイン
//                Auth.auth().signInAnonymously { (authResult, error) in
//                    guard let user = authResult?.user, error == nil else {
//                        print("匿名サインインに失敗しました:" ,error!.localizedDescription)
//                        return
//                    }
//                    print("匿名サインインに成功しました", user.uid)
//                }
//            }
//        })
//        self.authHandle.accept(authHandle)
//    }
//    //scrollLabelに流す本日のお得記事タイトルの取得
//    func fetchscrollTitle(){
//        let today = GetDateModel.gatToday()//Model直
//        var newScrollArray = [ScrollModel]()
//        Firestore.firestore().collection("OtokuWebData").document("2021-2022").collection("Day\(today)").addSnapshotListener { snapshots, error in
//            if let error = error {
//                print("情報の取得に失敗\(error)")
//                return
//            }
//            newScrollArray = []
//            if let snapShotDoc = snapshots?.documents{
//                for doc in snapShotDoc{
//                    let data = doc.data()
//                    if let scrolltitle = data["title"] as? String {
//                        let scrollModel = ScrollModel(title: scrolltitle)
//                        newScrollArray.append(scrollModel)
//                    }
//                }
//                self.scrollTitle.accept(newScrollArray)
//            }
//        }
//    }
//}
//extension CalendarModel:CalendarModelOutput{
//    var calendarModelObservable: Observable<[OtokuDataModel]> {
//        return calendarModel.asObservable()
//    }
//    var authHandleObserbable: Observable<AuthStateDidChangeListenerHandle> {
//        return authHandle.asObservable()
//    }
//    var scrollTitleObservable: Observable<[ScrollModel]>{
//        return scrollTitle.asObservable()
//    }
//}
//
