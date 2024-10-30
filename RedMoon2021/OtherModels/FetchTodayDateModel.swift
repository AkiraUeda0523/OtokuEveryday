//
//  FetchTodayDateModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2021/11/04.
//

import Foundation
// MARK: - Protocols
protocol FetchTodayDateModelInput {
    func fetchTodayDate() -> String
}
protocol FetchTodayDateModelType {
    var input: FetchTodayDateModelInput { get }
}
// MARK: - Input Implementation
class FetchTodayDateModel: FetchTodayDateModelInput {
    // 今日の日付を「dd」形式の文字列で取得するメソッド
    func fetchTodayDate() -> String {
        // 日付のフォーマットを設定
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .full
        dateFormatter.dateFormat = "yyyy/MM/dd"
        dateFormatter.locale = Locale(identifier: "ja_JP")
        // 現在の日付を取得
        let now = Date()
        // 日付を文字列に変換
        var today = dateFormatter.string(from: now)
        // 「yyyy/MM/dd」形式から「/」を削除して「yyyyMMdd」形式にする
        for _ in 0...1 {
            if let slash  = today.range(of: "/") {
                today.replaceSubrange(slash, with: "")
            }
        }
        // 日付の日部分を取得し、1桁の場合は先頭に「0」を付加
        let day = Int(today.suffix(2))
        let addZeroToday = String(format: "%02d", day!)
        // 加工された日付の文字列を返却
        return addZeroToday
    }
}
// MARK: - Additional Extensions
extension FetchTodayDateModel: FetchTodayDateModelType {
    var input: FetchTodayDateModelInput {return self}
}
