////
////  DayHandlingViewModel.swift
////  RedMoon2021
////
////  Created by 上田晃 on 2021/09/17.
////
//
//import FirebaseFirestore
//import RxSwift
//import RxCocoa
//
//
//
//final class DayHandlingModel {
//
//    var otokuModels: Observable<[OtokuModel]> {
//        otokuModelsRelay.asObservable()
//    }
//    var isLoading: Observable<Bool> {
//        isLoadingRelay.asObservable()
//    }
//
//    private let otokuModelsRelay = BehaviorRelay<[OtokuModel]>(value: [])
//    private let isLoadingRelay = PublishSubject<Bool>()
//    private let selectedDateRelay = BehaviorRelay<Date?>(value: nil)
//    private let bag = DisposeBag()
//
//    func update(selected: Date) {
//        selectedDateRelay.accept(selected)
//    }
//
//    init() {
//        selectedDateRelay
//            .subscribe(onNext: { [weak self] date in
//                guard let date = date else { return }
//                let formatter = DateFormatter()
//                formatter.dateFormat = "EEE MM-dd-YYYY"
//                let tmpDate = Calendar(identifier: .gregorian)
//                let tapDayInt = tmpDate.component(.day, from: date)
//                let addZeroTapDay = String(format: "%02d", tapDayInt)
//                Firestore.firestore().collection("OtokuWebData").document("2021-2022").collection("Day\(addZeroTapDay)").addSnapshotListener{ snapshots, error in
//                    if let error = error {
//                        print("情報の取得に失敗\(error)")
//                        return
//                    }
//                    var newArray: [OtokuModel] = []
//                    snapshots?.documents.forEach({ (snapshot) in
//                        let data = snapshot.data()
//                        if let information = OtokuModel(dic: data) {
//                            newArray.append(information)
//                        }
//                    })
//                    self?.otokuModelsRelay.accept(newArray)
//                }
//            })
//            .disposed(by: bag)
//
//        Observable.merge(
//            selectedDateRelay
//                .map { _ in true },
//            otokuModelsRelay
//                .map { _ in false }
//        )
//        .bind(to: isLoadingRelay)
//        .disposed(by: bag)
//
//
//
//
//
//        
//    }
//}
