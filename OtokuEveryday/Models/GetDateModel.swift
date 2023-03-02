//
//  GetDateModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2021/11/04.
//

import Foundation

class GetDateModel {
    static func getTodayDate(slash:Bool)->String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .full
        if slash == true{
            dateFormatter.dateFormat = "yyyy/MM/dd"
        }
        dateFormatter.locale = Locale(identifier: "ja_JP")
        let now = Date()
        return dateFormatter.string(from: now)
    }
    //MARK: -
   static func gatToday() -> String {
        var today = GetDateModel.getTodayDate(slash: true)
        for _ in 0...1{
            if let slash  = today.range(of: "/"){
                today.replaceSubrange(slash, with: "")
            }
        }
        let day = Int(today.suffix(2))
        let addZeroToday = String(format: "%02d", day!)
        return addZeroToday
    }
}
