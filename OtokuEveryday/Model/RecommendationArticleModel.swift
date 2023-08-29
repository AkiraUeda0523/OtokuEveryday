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
    var input: RecommendationArticleModelInput { get }
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
    private let imageCache = AutoPurgingImageCache()
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
