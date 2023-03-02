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


class CellBuilder:RecommendationArticleController {

    public override func viewDidLoad() {
        super.viewDidLoad()

    }
    static func getFeaturedCell(collectionView: UICollectionView, indexPath: IndexPath,RecommendArray1:[RecommendModel],RecommendArray4:[RecommendModel],RecommendArray7:[RecommendModel]) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "featured", for: indexPath) as? LargeRecommendCell {
            switch indexPath.section {
            case 1:
                cell.setup(title: RecommendArray1[indexPath.row].article_title, subtitle: RecommendArray1[indexPath.row].article_title, image: RecommendArray1[indexPath.row].collectionView_image_url)
            case 4:
                cell.setup(title: RecommendArray4[indexPath.row].article_title, subtitle: RecommendArray4[indexPath.row].article_title, image: RecommendArray4[indexPath.row].collectionView_image_url)
            case 7:
                cell.setup(title: RecommendArray7[indexPath.row].article_title, subtitle: RecommendArray7[indexPath.row].article_title, image: RecommendArray7[indexPath.row].collectionView_image_url)
            default:
                cell.setup(title: RecommendArray1[indexPath.row].article_title, subtitle: RecommendArray1[indexPath.row].article_title, image: RecommendArray1[indexPath.row].collectionView_image_url)
            }
            return cell
        } else {
            return UICollectionViewCell()
        }
    }

    public static func getTextCell(collectionView: UICollectionView, indexPath: IndexPath,title:[RecomendTitleModel] ) -> UICollectionViewCell {
        let title0 = title.filter {  $0.titleType == 0 }
        let title3 = title.filter {  $0.titleType == 3 }
        let title6 = title.filter {  $0.titleType == 6 }

        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "text", for: indexPath) as? RecommendTitleText {
            switch indexPath.section {
            case 0:

                cell.recommendLabel.text = title0[0].title
            case 3:

                cell.recommendLabel.text = title3[0].title
            case 6:

                cell.recommendLabel.text = title6[0].title
            default:
                let Arry:[String] = ["ヘッダー予定箇所１","ヘッダー予定箇所２","ヘッダー予定箇所３"]
                cell.recommendLabel.text = Arry[0]
            }
            return cell
        } else {
            return UICollectionViewCell()
        }
    }

    public static func getListCell(collectionView: UICollectionView, indexPath: IndexPath,RecommendArray2:[RecommendModel],RecommendArray5:[RecommendModel],RecommendArray8:[RecommendModel]) -> UICollectionViewCell {

        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? SmallRecommendCell {

            switch indexPath.section {
            case 2:

                cell.smallRecommendSubTitleLabel.text = RecommendArray2[indexPath.row].article_sub_title
                cell.smallRecommendTitleLabel.text = RecommendArray2[indexPath.row].article_title
                cell.smallRecommendView.sd_setImage(with: URL(string: RecommendArray2[indexPath.row].collectionView_image_url), completed: nil)
            case 5:

                cell.smallRecommendSubTitleLabel.text = RecommendArray5[indexPath.row].article_sub_title
                cell.smallRecommendTitleLabel.text = RecommendArray5[indexPath.row].article_title
                cell.smallRecommendView.sd_setImage(with: URL(string: RecommendArray5[indexPath.row].collectionView_image_url), completed: nil)
            case 8:

                cell.smallRecommendSubTitleLabel.text = RecommendArray8[indexPath.row].article_sub_title
                cell.smallRecommendTitleLabel.text = RecommendArray8[indexPath.row].article_title
                cell.smallRecommendView.sd_setImage(with: URL(string: RecommendArray8[indexPath.row].collectionView_image_url), completed: nil)
            default:

                cell.smallRecommendSubTitleLabel.text = RecommendArray2[indexPath.row].article_sub_title
                cell.smallRecommendTitleLabel.text = RecommendArray2[indexPath.row].article_title
                cell.smallRecommendView.sd_setImage(with: URL(string: RecommendArray2[indexPath.row].collectionView_image_url), completed: nil)
            }
            return cell
        } else {
            return UICollectionViewCell()
        }
    }
}

