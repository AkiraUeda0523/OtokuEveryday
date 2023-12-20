//
//  GetDateModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2021/11/04.
//

import Foundation
protocol FetchTodayDateModelInput{
    func fetchTodayDate() -> String
}
protocol FetchTodayDateModelType {
    var input: FetchTodayDateModelInput { get }
}
class FetchTodayDateModel: FetchTodayDateModelInput {
    func fetchTodayDate() ->String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .full
        dateFormatter.dateFormat = "yyyy/MM/dd"
        dateFormatter.locale = Locale(identifier: "ja_JP")
        let now = Date()
        var today = dateFormatter.string(from: now)
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
extension FetchTodayDateModel:FetchTodayDateModelType{
    //MARK: -
    var input: FetchTodayDateModelInput {return self}
}


