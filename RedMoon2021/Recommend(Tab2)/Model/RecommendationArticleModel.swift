//
//  RecommendationArticleModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2023/05/24.
//
import RxSwift
import RxCocoa
import Firebase
// MARK: - Protocols
protocol RecommendationArticleModelInput {
    func fetchRecommendData()
    func fetchRecommendTitle()
}
protocol RecommendationArticleModelOutput {
    var recommendDataObservable: Observable<[RecommendModel]> { get }
    var recommendTitleObservable: Observable<[RecommendModel]> { get }
}
protocol RecommendationArticleModelType {
    var input: RecommendationArticleModelInput { get }
    var output: RecommendationArticleModelOutput { get }
}
// MARK: -
struct  RecommendModel: Hashable {
    var article_title: String
    var article_sub_title: String
    var blog_web_url: String
    var collectionView_image_url: String
    var type: Int
    var month: Int
    var name: String
}
struct RecomendTitleModel: Hashable {
    var title: String
    var titleType: Int
}
// MARK: - Main Class
final class RecommendationArticleModel {
    private let recommendDataRelay = PublishRelay<[RecommendModel]>()
    private let recommendTitleRelay = PublishRelay<[RecommendModel]>()
}
// MARK: - Input Implementation
extension RecommendationArticleModel: RecommendationArticleModelInput {
    // Firestoreから「おすすめ記事」データを取得し、UIに反映するメソッド
    func fetchRecommendData() {
        var recommendBox: [RecommendModel] = []
        Firestore.firestore().collection("RecommendationArticle").getDocuments { snapshot, error in
            // 既存のデータをクリア
            recommendBox = []
            // スナップショット内のドキュメントを処理
            if let snapshotDocs = snapshot?.documents {
                for doc in snapshotDocs {
                    let data = doc.data()
                    // 必要なデータを取得し、RecommendModelに変換
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
                // 取得したデータをRelayを通じてUIに反映
                self.recommendDataRelay.accept(recommendBox)
            }
        }
    }
    // Firestoreから「Title」データを取得し、UIに反映するメソッド
    func fetchRecommendTitle() {
        var recommendTitleBox: [RecommendModel] = []
        Firestore.firestore().collection("RecommendationArticleTitle").getDocuments { snapShot, error in
            // 既存のデータをクリア
            recommendTitleBox = []
            // スナップショット内のドキュメントを処理
            if let snapShotDoc = snapShot?.documents {
                for doc in snapShotDoc {
                    let data = doc.data()
                    // 必要なデータを取得し、RecomendTitleModelに変換
                    if let title = data["title"] as? String,
                       let titleType = data["titleType"] as? Int {
                        let recommenTitleModel = RecommendModel(article_title: title, article_sub_title: "", blog_web_url: "", collectionView_image_url: "", type: titleType, month: 0, name: "")
                        recommendTitleBox.append(recommenTitleModel)
                    }
                }
                // 取得したデータをRelayを通じてUIに反映
                self.recommendTitleRelay.accept(recommendTitleBox)
            }
        }
    }
}
// MARK: - Output Implementation
extension RecommendationArticleModel: RecommendationArticleModelOutput {
    var recommendDataObservable: RxSwift.Observable<[RecommendModel]> {
        recommendDataRelay.asObservable()
    }
    var recommendTitleObservable: RxSwift.Observable<[RecommendModel]> {
        recommendTitleRelay.asObservable()
    }
}
// MARK: - Additional Extensions
extension RecommendationArticleModel: RecommendationArticleModelType {
    var input: RecommendationArticleModelInput { return self }
    var output: RecommendationArticleModelOutput { return self }
}
