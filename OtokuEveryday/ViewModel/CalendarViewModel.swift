//
//  CalendarViewModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2023/01/10.
//

import Foundation
import RxSwift
import RxCocoa
import RxRelay
import Firebase
import FirebaseAuth

protocol CalendarViewModelInput {
    var selectDateObserver: AnyObserver<Date> { get }
}
protocol CalendarViewModelOutput {
    var showableInfosObservable: Observable<[OtokuDataModel]> { get }
    var authObservable:Observable<AuthStateDidChangeListenerHandle> { get }
    var scrollTitleObservable:Observable<[ScrollModel]>  { get }
    var isLoadingObservable:Observable<Bool> { get }
}
protocol CalendarViewModelType {
    var input: CalendarViewModelInput { get }
    var output: CalendarViewModelOutput { get }

}
// MARK: -
final class CalendarViewModel{
    //input
    private let selectDateSubject = BehaviorSubject<Date>(value: Date())//初期値today
    private let articlesSubject = BehaviorSubject<[OtokuDataModel]>(value: [])
    //output
    private let showableInfos = BehaviorRelay<[OtokuDataModel]>(value: [])
    private let authSubject = PublishSubject<AuthStateDidChangeListenerHandle>()
    private let fetchscrollTitleSubject = BehaviorSubject<[ScrollModel]>(value: [])
    private let isLoadingRelay = PublishSubject<Bool>()

    let calendarModel: CalendarModelType
    let disposeBag = DisposeBag()
    // Initializer
    init(model: CalendarModelType) {
        calendarModel = model
        calendarModel.input.fetchAllOtokuDataFromRealTimeDB()
        calendarModel.input.authState()
        calendarModel.input.fetchscrollTitle()

        calendarModel
            .output
            .calendarModelObservable
            .subscribe { [self] data in
                articlesSubject.onNext(data)
            }
            .disposed(by: disposeBag)
        
        calendarModel
            .output
            .authHandleObserbable
            .subscribe{[self] auth in
                authSubject.onNext(auth)
            }
            .disposed(by: disposeBag)

        calendarModel
            .output
            .scrollTitleObservable
            .debug()
            .subscribe{[self] select in
                fetchscrollTitleSubject.onNext(select)}
            .disposed(by: disposeBag)
        //-------------------------------------------------------------------------------------------------------------------
        Observable
            .merge(
                selectDateSubject
                    .map { _ in true }
                    .debug("selectDateSubject"),
                showableInfos
                    .map { _ in false }
                    .debug("articlesSubject")
            )
            .debug("bind")
            .bind(to: isLoadingRelay)
            .disposed(by: disposeBag)

        Observable
            .combineLatest(selectDateSubject.asObserver(),articlesSubject.asObserver())
            .map { [self] selectDate, data in
                data.filter {
                    let date = addZeroTapString(date: selectDate)
                    return $0.enabled_dates.contains(date)
                }
            }
            .bind(to: showableInfos)
            .disposed(by: disposeBag)
    }

    private func addZeroTapString(date:Date) -> String {//Model?
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MM-dd-YYYY"
        let tmpDate = Calendar(identifier: .gregorian)
        let tapDayInt = tmpDate.component(.day, from: date)
        let addZeroTapDay = String(format: "%02d", tapDayInt)
        return addZeroTapDay
    }
}
//MARK: - ViewModel Extension
extension CalendarViewModel: CalendarViewModelType {
    var input: CalendarViewModelInput { return self }
    var output: CalendarViewModelOutput { return self }
}
extension CalendarViewModel:CalendarViewModelInput{
    var selectDateObserver: AnyObserver<Date> {
        return selectDateSubject.asObserver()
    }
}
extension CalendarViewModel:CalendarViewModelOutput{
    var showableInfosObservable: Observable<[OtokuDataModel]> {
        return showableInfos.asObservable()
    }
    var authObservable: Observable<AuthStateDidChangeListenerHandle>{
        return authSubject.asObservable()
    }
    var scrollTitleObservable: Observable<[ScrollModel]> {//??
        return fetchscrollTitleSubject.asObservable()
    }
    var isLoadingObservable:Observable<Bool> {
        return isLoadingRelay.asObservable()
    }
}


//データを取る
//当日を取得精製
//データに精製
//データを表示

//カレンダーのTAPをサブスクライブ
//日付を取得精製
//データを再精製
//データを再表示
