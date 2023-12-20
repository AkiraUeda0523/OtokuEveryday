//
//  MockAutoScrollModel.swift
//  RedMoon2021Tests
//
//  Created by 上田晃 on 2023/11/22.
//
import UIKit
@testable import RedMoon2021


//class MockAutoScrollModel: AutoScrollModelType, AutoScrollModelInput {
//    var input: AutoScrollModelInput { return self }
//
//    private var mockText: String = "2021年 1月 1日（金）"
//    private var mockAttributedText: NSAttributedString?
//    private var mockTextColor: UIColor = .black
//    private var mockFont: UIFont = UIFont.systemFont(ofSize: 26)
   
    
//    func autoScrollLabelLayoutArrange(scrollBaseViewsBounds: CGRect) -> AutoScrollModel {
//            // モックの状態を更新またはログ出力
//            let mockScrollLabel = AutoScrollModel()
//            mockScrollLabel.frame = scrollBaseViewsBounds
//            mockScrollLabel.backgroundColor = .white
//            mockScrollLabel.textColor = mockTextColor
//            mockScrollLabel.font = mockFont
//            mockScrollLabel.text = mockText
//            mockScrollLabel.attributedText = mockAttributedText
//
//            print("AutoScrollLabel layout arranged for mock. Text: \(mockText ?? "N/A")")
//            return mockScrollLabel
//        }

// テストやデモのための追加メソッドやプロパティをここに追加可能
// 例: モックのテキストや属性の設定、状態の取得など




class MockAutoScrollModel: UIView, AutoScrollModelType, AutoScrollModelInput {
    var input: AutoScrollModelInput { return self }
    
    var text: String?
    var attributedText: NSAttributedString?
    var textColor: UIColor = .black
    var font: UIFont = UIFont.systemFont(ofSize: 26)
    
    func autoScrollLabelLayoutArrange(scrollBaseViewsBounds: CGRect) -> AutoScrollModelType {
        // モックの状態を更新
        self.frame = scrollBaseViewsBounds
        self.backgroundColor = .white
        
        // ここで特定のテスト用の値を設定
        self.textColor = UIColor.red // または他の適切な値
        self.font = UIFont.boldSystemFont(ofSize: 30) // または他の適切な値
        self.text = "テスト用テキスト" // または他の適切な値
        self.attributedText = NSAttributedString(string: "テスト用", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20)]) // または他の適切な値
        
        print("AutoScrollLabel layout arranged for mock. Text: \(self.text ?? "N/A")")
        return self
    }
}
//
//    func autoScrollLabelLayoutArrange(scrollBaseViewsBounds: CGRect) -> AutoScrollModelType {
//        // モックの状態を更新
//        self.frame = scrollBaseViewsBounds
//        self.backgroundColor = .white
//        self.textColor = textColor
//        self.font = font
//        self.text = text
//        self.attributedText = attributedText
//
//        print("AutoScrollLabel layout arranged for mock. Text: \(text ?? "N/A")")
//        return self
//    }
    // 他の必要なメソッドやプロパティをここに追加



