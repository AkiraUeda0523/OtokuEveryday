//
//  LayoutBuilder.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2022/11/28.
//

import UIKit

public class LayoutBuilder {
    /// ヘッダー消去
    public static func rectangleHorizonContinuousWithHeaderSection(collectionViewBounds: CGRect) -> NSCollectionLayoutSection {
        let headerHeight = CGFloat(50)
        let headerElementKind = "header-element-kind"
        let insetSpacing = CGFloat(5)
        let rectangleItemWidth = collectionViewBounds.width * 1.1 / 1.9
        let rectangleItemHeight = rectangleItemWidth * (2.3/3)
        let rectangleItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),heightDimension: .fractionalHeight(1.0)))
        let horizonRectangleGroup = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(rectangleItemWidth),heightDimension: .absolute(rectangleItemHeight)),subitem: rectangleItem,count: 1)
        horizonRectangleGroup.contentInsets = NSDirectionalEdgeInsets(top: insetSpacing, leading: insetSpacing, bottom: insetSpacing, trailing: insetSpacing)
        let horizonRectangleContinuousSection = NSCollectionLayoutSection(group: horizonRectangleGroup)
        let sectionHeaderItem = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),heightDimension:.absolute(headerHeight)),elementKind: headerElementKind,alignment: .top)
        sectionHeaderItem.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: insetSpacing, bottom: 0, trailing: insetSpacing)
        horizonRectangleContinuousSection.orthogonalScrollingBehavior = .continuous // セクションに対して横スクロール属性を付与
        horizonRectangleContinuousSection.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: insetSpacing, bottom: 0, trailing: insetSpacing)

        return horizonRectangleContinuousSection
    }
    
    public static func buildHorizontalTableSectionLayout() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(70)))
        item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 20)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.9),  heightDimension: .fractionalHeight(0.6))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitem: item, count: 3)
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 70, trailing: 10)
        section.orthogonalScrollingBehavior = .groupPaging
        return section
    }

    public static func buildTextSectionLayout() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(70)))
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),  heightDimension: .estimated(70))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
        return section
    }
}


