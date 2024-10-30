//
//  RecommendationArticleModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2023/05/24.
//

import RxSwift
import RxCocoa
import Firebase
import AlamofireImage

protocol RecommendationArticleModelInput {
    func fetchRecommendData()
    func fetchRecommendTitle()
}
protocol RecommendationArticleModelOutput {
    var recommendDataObservable: Observable<[RecommendModel]> { get }
    var recommendTitleObservable: Observable<[RecomendTitleModel]> { get }
}
protocol RecommendationArticleModelType {
    var input: RecommendationArticleModelInput { get }//in,outがあるだけでMとみなすと言うこと
    var output: RecommendationArticleModelOutput { get }
}
struct  RecommendModel:Hashable{
    var article_title:String
    var article_sub_title:String
    var blog_web_url:String
    var collectionView_image_url:String
    var type:Int//intへ変更⚠️
    var month:Int//intへ変更⚠️
    var name:String
}
struct RecomendTitleModel:Hashable{
    var title:String
    var titleType:Int
}



final class RecommendationArticleModel{
    private let recommendDataRelay = BehaviorRelay<[RecommendModel]>(value: [])
    private let recommendTitleRelay = BehaviorRelay<[RecomendTitleModel]>(value: [])
    private let imageCache = AutoPurgingImageCache() // Add this line

}
extension RecommendationArticleModel:RecommendationArticleModelInput{
    func fetchRecommendData() {
        var recommendBox: [RecommendModel] = []

        Firestore.firestore().collection("RecommendationArticle").addSnapshotListener { snapshot, error in
            recommendBox = []
            if let snapshotDocs = snapshot?.documents {

                for doc in snapshotDocs {
                    let data = doc.data()
                    if let articleTitle = data["article_title"],
                       let blogWebUrl = data["blog_web_url"],
                       let collectionViewImageUrlString = data["collectionView_image_url"],
                       let collectionViewImageUrl = URL(string: collectionViewImageUrlString as! String),
                       let type = data["type"],
                       let month = data["month"],
                       let name = data["name"] {

                        let articleSubTitle = data["article_sub_title"] as? String
                        let recommendModel = RecommendModel(article_title: articleTitle as! String, article_sub_title: articleSubTitle ?? "", blog_web_url: blogWebUrl as! String, collectionView_image_url: collectionViewImageUrl.absoluteString, type: type as? Int ?? 0, month: month as? Int ?? 0, name: name as! String)
                        recommendBox.append(recommendModel)
                    }
                }

                self.recommendDataRelay.accept(recommendBox)
            }
        }
    }
//--------------------------------------------------------------------------------------------------------
    func fetchRecommendTitle(){
        var recommendTitleBox:[RecomendTitleModel] = []
        
        Firestore.firestore().collection("RecommendationArticleTitle").addSnapshotListener { snapShot, error in
            recommendTitleBox = []
            if let snapShotDoc = snapShot?.documents{
                for doc in snapShotDoc{
                    let data = doc.data()
                    if let title = data["title"] as? String,
                       let titleType = data["titleType"] as? Int {
                        let recommenTitleModel = RecomendTitleModel(title: title, titleType: titleType)
                        recommendTitleBox.append(recommenTitleModel)
                    }
                }
                //                let select = recommendTitleBox.filter {$0.titleType == 0}
                self.recommendTitleRelay.accept(recommendTitleBox)
            }
        }
    }
}
extension RecommendationArticleModel:RecommendationArticleModelOutput{
    var recommendDataObservable: RxSwift.Observable<[RecommendModel]> {
        recommendDataRelay.asObservable()
    }
    var recommendTitleObservable: RxSwift.Observable<[RecomendTitleModel]> {
        recommendTitleRelay.asObservable()
    }
}
extension RecommendationArticleModel:RecommendationArticleModelType{
    var input: RecommendationArticleModelInput { return self }
    var output: RecommendationArticleModelOutput { return self }
}


//    func fetchRecommendData(){
//        var recommendBox:[RecommendModel] = []
//
//        Firestore.firestore().collection("RecommendationArticle").addSnapshotListener { snapShot, error in
//            recommendBox = []
//            if let snapShotDoc = snapShot?.documents{
//                for doc in snapShotDoc{
//                    let data = doc.data()
//                    if let articleTitle = data["article_title"], let blogWebUrl = data["blog_web_url"] ,
//                       let collectionViewImageUrl = data["collectionView_image_url"] ,
//                       let type = data["type"] ,
//                       let month = data["month"],
//                       let name = data["name"]{
//                        let articleSubTitle = data["article_sub_title"] as? String
//                        let recommenModel = RecommendModel(article_title: articleTitle as! String,article_sub_title: articleSubTitle ?? "", blog_web_url: blogWebUrl as! String, collectionView_image_url:collectionViewImageUrl as! String , type: type as? Int ?? 0, month:month as? Int ?? 0 ,name: name as! String)
//                        recommendBox.append(recommenModel)
//                    }
//                }
//                self.recommendDataRelay.accept(recommendBox)
//                //                let select = recommendBox.filter {$0.type == 1}
//            }
//        }
//    }
//    func fetchRecommendData() {
//        var recommendBox: [RecommendModel] = []
//
//        Firestore.firestore().collection("RecommendationArticle").addSnapshotListener { snapshot, error in
//            recommendBox = []
//            if let snapshotDocs = snapshot?.documents {
//                let downloader = ImageDownloader.default
//
//                let dispatchGroup = DispatchGroup()
//
//                for doc in snapshotDocs {
//                    let data = doc.data()
//                    if let articleTitle = data["article_title"],
//                       let blogWebUrl = data["blog_web_url"],
//                       let collectionViewImageUrlString = data["collectionView_image_url"],
//                       let collectionViewImageUrl = URL(string: collectionViewImageUrlString as! String),
//                       let type = data["type"],
//                       let month = data["month"],
//                       let name = data["name"] {
//
//                        dispatchGroup.enter()
//                        let urlRequest = URLRequest(url: collectionViewImageUrl)
//                        downloader.download(urlRequest) { response in
//                            switch response.result {
//                            case .success(let image):
//                                // Image has been successfully downloaded and cached
//                                print("Image downloaded and cached!")//呼ばれまくるinitで
//                            case .failure(let error):
//                                print(error)
//                            }
//                            dispatchGroup.leave()
//                        }
//
//                        let articleSubTitle = data["article_sub_title"] as? String
//                        let recommendModel = RecommendModel(article_title: articleTitle as! String, article_sub_title: articleSubTitle ?? "", blog_web_url: blogWebUrl as! String, collectionView_image_url: collectionViewImageUrl.absoluteString, type: type as? Int ?? 0, month: month as? Int ?? 0, name: name as! String)
//                        recommendBox.append(recommendModel)
//                    }
//                }
//
//                dispatchGroup.notify(queue: .main) {
//                    self.recommendDataRelay.accept(recommendBox)
//                }
//            }
//        }
//    }
//ーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーー
//import RxSwift
//import RxCocoa
//import Firebase
//
//protocol RecommendationArticleModelInput {
//    func fetchRecommendData()
//    func fetchRecommendTitle()
//}
//protocol RecommendationArticleModelOutput {
//    var recommendDataObservable: Observable<[RecommendModel]> { get }
//    var recommendTitleObservable: Observable<[RecomendTitleModel]> { get }
//}
//protocol RecommendationArticleModelType {
//    var input: RecommendationArticleModelInput { get }
//    var output: RecommendationArticleModelOutput { get }
//}
//struct  RecommendModel:Hashable{
//    var article_title:String
//    var article_sub_title:String
//    var blog_web_url:String
//    var collectionView_image_url:String
//    var type:Int
//    var month:Int
//    var name:String
//}
//struct RecomendTitleModel:Hashable{
//    var title:String
//    var titleType:Int
//}
//
//final class RecommendationArticleModel{
//    private let recommendDataRelay = BehaviorRelay<[RecommendModel]>(value: [])
//    private let recommendTitleRelay = BehaviorRelay<[RecomendTitleModel]>(value: [])
//}
//extension RecommendationArticleModel:RecommendationArticleModelInput{
//    func fetchRecommendData() {
//        var recommendBox: [RecommendModel] = []
//
//        Firestore.firestore().collection("RecommendationArticle").addSnapshotListener { snapshot, error in
//            recommendBox = []
//            if let snapshotDocs = snapshot?.documents {
//                for doc in snapshotDocs {
//                    let data = doc.data()
//                    if let articleTitle = data["article_title"],
//                       let blogWebUrl = data["blog_web_url"],
//                       let collectionViewImageUrlString = data["collectionView_image_url"],
//                       let collectionViewImageUrl = URL(string: collectionViewImageUrlString as! String),
//                       let type = data["type"],
//                       let month = data["month"],
//                       let name = data["name"] {
//
//                        let articleSubTitle = data["article_sub_title"] as? String
//                        let recommendModel = RecommendModel(article_title: articleTitle as! String, article_sub_title: articleSubTitle ?? "", blog_web_url: blogWebUrl as! String, collectionView_image_url: collectionViewImageUrl.absoluteString, type: type as? Int ?? 0, month: month as? Int ?? 0, name: name as! String)
//                        recommendBox.append(recommendModel)
//                    }
//                }
//                self.recommendDataRelay.accept(recommendBox)
//            }
//        }
//    }
////--------------------------------------------------------------------------------------------------------
//    func fetchRecommendTitle(){
//        var recommendTitleBox:[RecomendTitleModel] = []
//
//        Firestore.firestore().collection("RecommendationArticleTitle").addSnapshotListener { snapShot, error in
//            recommendTitleBox = []
//            if let snapShotDoc = snapShot?.documents{
//                for doc in snapShotDoc{
//                    let data = doc.data()
//                    if let title = data["title"] as? String,
//                       let titleType = data["titleType"] as? Int {
//                        let recommenTitleModel = RecomendTitleModel(title: title, titleType: titleType)
//                        recommendTitleBox.append(recommenTitleModel)
//                    }
//                }
//                self.recommendTitleRelay.accept(recommendTitleBox)
//            }
//        }
//    }
//}
//extension RecommendationArticleModel:RecommendationArticleModelOutput{
//    var recommendDataObservable: RxSwift.Observable<[RecommendModel]> {
//        recommendDataRelay.asObservable()
//    }
//    var recommendTitleObservable: RxSwift.Observable<[RecomendTitleModel]> {


//func fetchRecommendData() {
//    var recommendBox: [RecommendModel] = []
//
//    Firestore.firestore().collection("RecommendationArticle").addSnapshotListener { snapshot, error in
//        recommendBox = []
//        if let snapshotDocs = snapshot?.documents {
//            let downloader = ImageDownloader.default
//
//            let dispatchGroup = DispatchGroup()
//
//            for doc in snapshotDocs {
//                let data = doc.data()
//                if let articleTitle = data["article_title"],
//                   let blogWebUrl = data["blog_web_url"],
//                   let collectionViewImageUrlString = data["collectionView_image_url"],
//                   let collectionViewImageUrl = URL(string: collectionViewImageUrlString as! String),
//                   let type = data["type"],
//                   let month = data["month"],
//                   let name = data["name"] {
//
//                    let articleSubTitle = data["article_sub_title"] as? String
//                    let recommendModel = RecommendModel(article_title: articleTitle as! String, article_sub_title: articleSubTitle ?? "", blog_web_url: blogWebUrl as! String, collectionView_image_url: collectionViewImageUrl.absoluteString, type: type as? Int ?? 0, month: month as? Int ?? 0, name: name as! String)
//                    recommendBox.append(recommendModel)
//
//                    dispatchGroup.enter()
//                    let urlRequest = URLRequest(url: collectionViewImageUrl)
//                    if self.imageCache.image(for: urlRequest, withIdentifier: collectionViewImageUrl.absoluteString) == nil {
//                        downloader.download(urlRequest) { response in
//                            switch response.result {
//                            case .success(let image):
//                                // Image has been successfully downloaded and cached
//                                print("Image downloaded and cached!")
//                                // Add the image to the AutoPurgingImageCache
//                                self.imageCache.add(image, withIdentifier: collectionViewImageUrl.absoluteString)
//                            case .failure(let error):
//                                print(error)
//                            }
//                            dispatchGroup.leave()
//                        }
//                    } else {
//                        dispatchGroup.leave()
//                    }
//                }
//            }
//
//            dispatchGroup.notify(queue: .main) {
//                self.recommendDataRelay.accept(recommendBox)
//            }
//        }
//    }
//}
//
//func getImage(for url: URL) -> Image? {
//    return imageCache.image(withIdentifier: url.absoluteString)
//}
