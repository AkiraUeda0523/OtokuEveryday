////
////  LayoutBuilder.swift
////  RedMoon2021
////
////  Created by 上田晃 on 2022/11/28.
////
//
import UIKit

struct PagingInfo {
    var sectionIndex: Int
    var currentPage: Int
}
// MARK: -
protocol LayoutBuild {
    func buildLargeHorizontalSectionWithFooter(recommendViewBounds: CGRect) -> NSCollectionLayoutSection
    func buildSmallHorizontalSectionWithFooter(recommendViewBounds: CGRect) -> NSCollectionLayoutSection
    func buildTextSectionLayout(recommendViewBounds: CGRect) -> NSCollectionLayoutSection
}
final class LayoutBuilder: LayoutBuild {
    
    public func buildLargeHorizontalSectionWithFooter(recommendViewBounds: CGRect) -> NSCollectionLayoutSection {
        let footerHeight = CGFloat(10)
        let totalHeightRatio: CGFloat = 8 + 14 + 2
        let contentHeight = recommendViewBounds.height
        let largeSectionHeight = contentHeight * (8 / totalHeightRatio) - footerHeight
        let footerElementKind = UICollectionView.elementKindSectionFooter
        let insetSpacing = CGFloat(5)
        // アイテムの横幅を recommendViewBounds の 80% に設定
        let rectangleItemWidth = recommendViewBounds.width * 0.6
        let rectangleItemHeight = largeSectionHeight
        let rectangleItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))
        let horizonRectangleGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(rectangleItemWidth), heightDimension: .absolute(rectangleItemHeight)),
            repeatingSubitem: rectangleItem,
            count: 1
        )
        horizonRectangleGroup.contentInsets = NSDirectionalEdgeInsets(top: insetSpacing, leading: insetSpacing, bottom: insetSpacing, trailing: insetSpacing)
        let horizonRectangleContinuousSection = NSCollectionLayoutSection(group: horizonRectangleGroup)
        let sectionFooterItem = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(footerHeight)),
            elementKind: footerElementKind,
            alignment: .bottom
        )
        horizonRectangleContinuousSection.orthogonalScrollingBehavior = .groupPaging
        horizonRectangleContinuousSection.boundarySupplementaryItems = [sectionFooterItem]
        horizonRectangleContinuousSection.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        //これ何の為　　スクロールによって左右にバウンスするのを防ぐためのロジック
        horizonRectangleContinuousSection.visibleItemsInvalidationHandler = { (items, offset, environment) in
            items.forEach { item in
                if item.representedElementKind == UICollectionView.elementKindSectionFooter {
                    let sectionWidth = environment.container.contentSize.width
                    let containerWidth = environment.container.contentSize.width
                    if offset.x <= 0 {
                        // 左端でのバウンスを制限
                        item.center.x = max(item.bounds.width / 2, item.center.x)
                    } else if offset.x >= sectionWidth - containerWidth {
                        // 右端でのバウンスを制限
                        item.center.x = min(sectionWidth - item.bounds.width / 2, item.center.x)
                    }
                }
            }
        }
        return horizonRectangleContinuousSection
    }
    // MARK: -
    public func buildSmallHorizontalSectionWithFooter(recommendViewBounds: CGRect) -> NSCollectionLayoutSection {
        let footerHeight = CGFloat(50)
        let topPadding: CGFloat = 10  // 上部に設けるスペース
        let totalHeightRatio: CGFloat = 8 + 14 + 2
        let contentHeight = recommendViewBounds.height
        let smallSectionHeight = contentHeight * (14 / totalHeightRatio) - footerHeight - topPadding  // 上部スペースを引く
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(smallSectionHeight / 3.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 20) // アイテム間に2ポイントのスペースを設定
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.9), heightDimension: .absolute(smallSectionHeight))
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: groupSize,
            repeatingSubitem: item,
            count: 3
        )
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPagingCentered
        section.contentInsets = NSDirectionalEdgeInsets(top: topPadding, leading: 10, bottom: 0, trailing: 10)
        let footerElementKind = UICollectionView.elementKindSectionFooter
        let sectionFooterItem = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(footerHeight)),
            elementKind: footerElementKind,
            alignment: .bottom
        )
        section.boundarySupplementaryItems = [sectionFooterItem]
        return section
    }
    // MARK: -
    public func buildTextSectionLayout(recommendViewBounds: CGRect) -> NSCollectionLayoutSection {
        let totalHeightRatio: CGFloat = 8 + 14 + 2
        let contentHeight = recommendViewBounds.height
        let textSectionHeight = contentHeight * (2 / totalHeightRatio)
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(textSectionHeight)))
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(textSectionHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: 1)
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        
        return section
    }
}

