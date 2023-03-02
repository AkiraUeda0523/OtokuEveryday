//
//  CalendarsLayout.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2023/01/03.
//

import Foundation
import FSCalendar
import CalculateCalendarLogic




class CalendarsLayout{


    static func calendarsLayout(calendar:FSCalendar){
        calendar.appearance.headerDateFormat = "YYYY年MM月"
        calendar.appearance.titleWeekendColor = .red //週末（土、日曜の日付表示カラー）
        calendar.appearance.todaySelectionColor = .systemRed
        calendar.appearance.todayColor = .lightGray
        calendar.appearance.headerTitleColor = .black //ヘッダーテキストカラー
        // calendarの曜日部分を日本語表記に変更
        calendar.calendarWeekdayView.weekdayLabels[0].text = "日"
        calendar.calendarWeekdayView.weekdayLabels[1].text = "月"
        calendar.calendarWeekdayView.weekdayLabels[2].text = "火"
        calendar.calendarWeekdayView.weekdayLabels[3].text = "水"
        calendar.calendarWeekdayView.weekdayLabels[4].text = "木"
        calendar.calendarWeekdayView.weekdayLabels[5].text = "金"
        calendar.calendarWeekdayView.weekdayLabels[6].text = "土"
        // calendarの曜日部分の色を変更
        calendar.calendarWeekdayView.weekdayLabels[0].textColor = .systemRed
        calendar.calendarWeekdayView.weekdayLabels[1].textColor = .black
        calendar.calendarWeekdayView.weekdayLabels[2].textColor = .black
        calendar.calendarWeekdayView.weekdayLabels[3].textColor = .black
        calendar.calendarWeekdayView.weekdayLabels[4].textColor = .black
        calendar.calendarWeekdayView.weekdayLabels[5].textColor = .black
        calendar.calendarWeekdayView.weekdayLabels[6].textColor = .systemIndigo
    }

    // 祝日判定を行い結果を返すメソッド(True:祝日)
    static  func judgeHoliday(_ date : Date) -> Bool {
        //祝日判定用のカレンダークラスのインスタンス
        let tmpCalendar = Calendar(identifier: .gregorian)
        // 祝日判定を行う日にちの年、月、日を取得
        let year = tmpCalendar.component(.year, from: date)
        let month = tmpCalendar.component(.month, from: date)
        let day = tmpCalendar.component(.day, from: date)
        // CalculateCalendarLogic()：祝日判定のインスタンスの生成
        let holiday = CalculateCalendarLogic()
        return holiday.judgeJapaneseHoliday(year: year, month: month, day: day)
    }
//    // date型 -> 年月日をIntで取得
//    static   func getDay(_ date:Date) -> (Int,Int,Int){
//        let tmpCalendar = Calendar(identifier: .gregorian)
//        let year = tmpCalendar.component(.year, from: date)
//        let month = tmpCalendar.component(.month, from: date)
//        let day = tmpCalendar.component(.day, from: date)
//        return (year,month,day)
//    }

//    static  func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
//        calendar.reloadData()
//    }
    //曜日判定(日曜日:1 〜 土曜日:7)
    static  func getWeekIdx(_ date: Date) -> Int{
        let tmpCalendar = Calendar(identifier: .gregorian)
        return tmpCalendar.component(.weekday, from: date)
    }
//    // 土日や祝日の日の文字色を変える
//    static   func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
//        if calendar.scope == .month {
//            //  現在表示されているページの月とセルの月が異なる場合には nil を戻す
//            if Calendar.current.compare(date, to: calendar.currentPage, toGranularity: .month) != .orderedSame {
//                return nil
//            }
//        }
//        //祝日判定をする（祝日は赤色で表示する）
//        if self.judgeHoliday(date){
//            return UIColor.red
//        }
//        //土日の判定を行う（土曜日は青色、日曜日は赤色で表示する）
//        let weekday = self.getWeekIdx(date)
//        if weekday == 1 {   //日曜日
//            return UIColor.red
//        }
//        else if weekday == 7 {  //土曜日
//            return UIColor.systemBlue
//        }
//        return nil
//    }

    

}


