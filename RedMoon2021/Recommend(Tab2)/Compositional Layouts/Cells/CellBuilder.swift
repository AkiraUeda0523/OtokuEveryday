////
////  CellBuilder.swift
////  RedMoon2021
////
////  Created by 上田晃 on 2022/11/28.
////
import Nuke

class CellBuilder: RecommendationArticleController {
    public static func getTitleCell(collectionView: UICollectionView, indexPath: IndexPath, recommendModel: RecommendModel) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "text", for: indexPath) as? RecommendTitleText  {
            cell.recommendLabel.text = recommendModel.article_title
            return cell
        } else {
            return UICollectionViewCell()
        }
    }
    public static func getLargeCell(collectionView: UICollectionView, indexPath: IndexPath, recommendModel: RecommendModel) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "featured", for: indexPath) as? LargeRecommendCell {
            // セルにデータを設定
            cell.setup(subtitle: recommendModel.article_title, image: recommendModel.collectionView_image_url)
            return cell
        } else {
            return UICollectionViewCell()
        }
    }
    public static func getSmallCell(collectionView: UICollectionView, indexPath: IndexPath, recommendModel: RecommendModel) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? SmallRecommendCell else {
            return UICollectionViewCell()
        }
        // セルにデータを設定
        setupCell(cell: cell, with: recommendModel)
        return cell
    }
    // MARK: -
    private static func setupCell(cell: SmallRecommendCell, with model: RecommendModel) {
        cell.smallRecommendSubTitleLabel.text = model.article_sub_title
        cell.smallRecommendTitleLabel.text = model.article_title
        let imageUrl = URL(string: model.collectionView_image_url) ?? URL(string: "https://harigamiya.jp/2x/in-preparetion-1@2x-100.jpg")!
        Nuke.loadImage(with: imageUrl, into: cell.smallRecommendView)
    }
}
