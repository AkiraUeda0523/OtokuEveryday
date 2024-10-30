//
//  Alert.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2022/11/02.
//

import UIKit
// アラート表示のユーティリティクラス
final class Alert {
    // OKボタンのみのアラートを表示
    static func okAlert(vc: UIViewController, title: String, message: String, handler: ((UIAlertAction) -> Void)? = nil) {
        // UIAlertControllerを作成
        let okAlertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        // 閉じるボタンの設定
        let cancelAction: UIAlertAction = UIAlertAction(title: "閉じる", style: UIAlertAction.Style.cancel, handler: {
            (action: UIAlertAction!) -> Void in
        })
        okAlertVC.addAction(cancelAction)
        // 設定ボタンの設定
        okAlertVC.addAction(UIAlertAction(title: "設定", style: .default, handler: handler))
        // アラートを表示
        vc.present(okAlertVC, animated: true, completion: nil)
    }
}
