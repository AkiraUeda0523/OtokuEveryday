//
//  CalenderColectionViewLayout.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2023/02/07.
//

import Foundation
import UIKit


class CalenderColectionViewLayout{
    static func CalenderColectionViewLayout(cell:OtokuCollectionViewCell,rxOtokuArray:[OtokuDataModel],indexPath:IndexPath){
        cell.otokuLabel.text = rxOtokuArray[indexPath.row].article_title
        cell.otokuImage.af.setImage(withURL: (URL(string: rxOtokuArray[indexPath.row].collectionView_image_url) ?? URL(string: "https://harigamiya.jp/2x/in-preparetion-1@2x-100.jpg"))!,imageTransition: .crossDissolve(0.5))//.curlDown(2)//.crossDissolve(0.5))

        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOpacity = 8
        cell.layer.shadowRadius = 8.0
        cell.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)


    }

    static  func calendarCollectionViewLayout(view:UIView,layout:UICollectionViewFlowLayout){
        let width = view.frame.width
        layout.itemSize = CGSize(width: (width - 20)/3 , height: (width - 20)/3)
    }

    
}
