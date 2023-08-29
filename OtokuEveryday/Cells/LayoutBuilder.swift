//
//  LayoutBuilder.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2022/11/28.
//

import UIKit
import RxSwift
import RxCocoa

struct PagingInfo {
    var sectionIndex: Int
    var currentPage: Int
}

public class LayoutBuilder {
    
    public static func rectangleHorizonContinuousWithFooterSection(collectionViewBounds: CGRect) -> NSCollectionLayoutSection {
        let footerHeight = CGFloat(10)
        let footerElementKind = UICollectionView.elementKindSectionFooter
        let insetSpacing = CGFloat(5)
        let rectangleItemWidth = collectionViewBounds.width * 1.1 / 1.9
        let rectangleItemHeight = rectangleItemWidth * (2.3/3)
        let rectangleItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))
        let horizonRectangleGroup = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(rectangleItemWidth), heightDimension: .absolute(rectangleItemHeight)), subitem: rectangleItem, count: 1)
        horizonRectangleGroup.contentInsets = NSDirectionalEdgeInsets(top: insetSpacing, leading: insetSpacing, bottom: insetSpacing, trailing: insetSpacing)
        let horizonRectangleContinuousSection = NSCollectionLayoutSection(group: horizonRectangleGroup)
        let sectionFooterItem = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(footerHeight)),
            elementKind: footerElementKind,
            alignment: .bottom)
        sectionFooterItem.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: insetSpacing, bottom: 0, trailing: insetSpacing)
        horizonRectangleContinuousSection.orthogonalScrollingBehavior = .continuous
        horizonRectangleContinuousSection.boundarySupplementaryItems = [sectionFooterItem]
        horizonRectangleContinuousSection.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: insetSpacing, bottom: 0, trailing: insetSpacing)
        return horizonRectangleContinuousSection
    }
    
    
    public static func buildHorizontalTableSectionLayout(collectionViewBounds: CGRect) -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(70)))
        item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 20)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.9),  heightDimension: .fractionalHeight(0.6))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitem: item, count: 3)
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 8, trailing: 10)
        section.orthogonalScrollingBehavior = .groupPaging
        let footerHeight = CGFloat(10)
        let footerElementKind = UICollectionView.elementKindSectionFooter
        let insetSpacing = CGFloat(5)
        let sectionFooterItem = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(footerHeight)),
            elementKind: footerElementKind,
            alignment: .bottom)
        sectionFooterItem.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: insetSpacing, bottom: 50, trailing: insetSpacing)
        section.boundarySupplementaryItems = [sectionFooterItem]
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
