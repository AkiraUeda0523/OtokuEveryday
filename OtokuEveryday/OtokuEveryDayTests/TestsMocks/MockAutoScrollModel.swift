//
//  MockAutoScrollModel.swift
//  RedMoon2021Tests
//
//  Created by 上田晃 on 2023/11/22.
//
import UIKit
@testable import RedMoon2021


class MockAutoScrollModel: UIView, AutoScrollModelType, AutoScrollModelInput {
    var input: AutoScrollModelInput { return self }
    
    var text: String?
    var attributedText: NSAttributedString?
    var textColor: UIColor = .black
    var font: UIFont = UIFont.systemFont(ofSize: 26)
    
    func autoScrollLabelLayoutArrange(scrollBaseViewsBounds: CGRect) -> AutoScrollModelType {
        self.frame = scrollBaseViewsBounds
        self.backgroundColor = .white
        
        self.textColor = UIColor.red
        self.font = UIFont.boldSystemFont(ofSize: 30)
        self.text = "テスト用テキスト"
        self.attributedText = NSAttributedString(string: "テスト用", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20)])
        
        print("AutoScrollLabel layout arranged for mock. Text: \(self.text ?? "N/A")")
        return self
    }
}


