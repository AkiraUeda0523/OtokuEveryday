//
//  CellBuilder.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2022/11/28.
//

import UIKit
import Firebase
import FirebaseFirestore
import AlamofireImage
import Nuke

class CellBuilder:RecommendationArticleController {
    static func getFeaturedCell(collectionView: UICollectionView, indexPath: IndexPath, RecommendArray1:[RecommendModel], RecommendArray4:[RecommendModel], RecommendArray7:[RecommendModel]) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "featured", for: indexPath) as? LargeRecommendCell {
            switch indexPath.section {
            case 1:
                if indexPath.row < RecommendArray1.count {
                    cell.setup(title: RecommendArray1[indexPath.row].article_title, subtitle: RecommendArray1[indexPath.row].article_title, image: RecommendArray1[indexPath.row].collectionView_image_url)
                }
            case 4:
                if indexPath.row < RecommendArray4.count {
                    cell.setup(title: RecommendArray4[indexPath.row].article_title, subtitle: RecommendArray4[indexPath.row].article_title, image: RecommendArray4[indexPath.row].collectionView_image_url)
                }
            case 7:
                if indexPath.row < RecommendArray7.count {
                    cell.setup(title: RecommendArray7[indexPath.row].article_title, subtitle: RecommendArray7[indexPath.row].article_title, image: RecommendArray7[indexPath.row].collectionView_image_url)
                }
            default:
                if indexPath.row < RecommendArray1.count {
                    cell.setup(title: RecommendArray1[indexPath.row].article_title, subtitle: RecommendArray1[indexPath.row].article_title, image: RecommendArray1[indexPath.row].collectionView_image_url)
                }
            }
            return cell
        } else {
            return UICollectionViewCell()
        }
    }
    public static func getTextCell(collectionView: UICollectionView, indexPath: IndexPath, title: [RecomendTitleModel]) -> UICollectionViewCell {
        let titlesForSections = [
            0: title.first(where: { $0.titleType == 0 })?.title ?? "ヘッダー予定箇所１",
            3: title.first(where: { $0.titleType == 3 })?.title ?? "ヘッダー予定箇所２",
            6: title.first(where: { $0.titleType == 6 })?.title ?? "ヘッダー予定箇所３"
        ]
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "text", for: indexPath) as? RecommendTitleText else {
            return UICollectionViewCell()
        }
        let titleText = titlesForSections[indexPath.section] ?? "ヘッダー予定箇所１"
        cell.recommendLabel.text = titleText
        return cell
    }
    public static func getListCell(collectionView: UICollectionView, indexPath: IndexPath, RecommendArray2:[RecommendModel], RecommendArray5:[RecommendModel], RecommendArray8:[RecommendModel]) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? SmallRecommendCell else {
            return UICollectionViewCell()
        }
        let recommendArray: [RecommendModel]
        switch indexPath.section {
        case 2:
            recommendArray = RecommendArray2
        case 5:
            recommendArray = RecommendArray5
        case 8:
            recommendArray = RecommendArray8
        default:
            recommendArray = RecommendArray2
        }
        
        if indexPath.row < recommendArray.count {
            let recommendModel = recommendArray[indexPath.row]
            setupCell(cell: cell, with: recommendModel)
        }
        return cell
    }
    private static func setupCell(cell: SmallRecommendCell, with model: RecommendModel) {
        cell.smallRecommendSubTitleLabel.text = model.article_sub_title
        cell.smallRecommendTitleLabel.text = model.article_title
        
        let imageUrl = URL(string: model.collectionView_image_url) ?? URL(string: "https://harigamiya.jp/2x/in-preparetion-1@2x-100.jpg")!
        Nuke.loadImage(with: imageUrl, into: cell.smallRecommendView)
    }
}
