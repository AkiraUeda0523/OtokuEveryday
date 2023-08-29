//
//  Alert.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2022/11/02.
//

import UIKit

final class Alert {
    static func okAlert(vc: UIViewController,title: String, message: String, handler: ((UIAlertAction) -> Void)? = nil) {
        let okAlertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction: UIAlertAction = UIAlertAction(title: "閉じる", style: UIAlertAction.Style.cancel, handler:{
            (action: UIAlertAction!) -> Void in
        })
        okAlertVC.addAction(cancelAction)
        okAlertVC.addAction(UIAlertAction(title: "設定", style: .default, handler: handler))
        vc.present(okAlertVC, animated: true, completion: nil)
    }
}
