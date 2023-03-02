//
//  MapStateManagementModel .swift
//  RedMoon2021
//
//  Created by 上田晃 on 2022/11/03.
//

import Foundation
import RxSwift
import RxCocoa
import RxRelay
import CoreLocation

final class MapStateManagementModel{
    public static let shared = MapStateManagementModel()
    private let disposeBag = DisposeBag()
    
    var foregroundJudgeRelay = BehaviorRelay<Bool>(value: true)
    var currentlyDisplayedVCRelay = BehaviorRelay<Bool>(value: true)
    var userLocationStatusRelay = PublishRelay<CLAuthorizationStatus>()
    
    var foregroundJudge: Observable<Bool> {
        foregroundJudgeRelay.asObservable()
    }
    var currentlyDisplayed: Observable<Bool> {
        currentlyDisplayedVCRelay.asObservable()
    }
    var LocationStatus: Observable<CLAuthorizationStatus> {
        userLocationStatusRelay.asObservable()
    }
    var didEnterBackground:Observable<Bool> {
        return NotificationCenter.default.rx.notification(UIApplication.didEnterBackgroundNotification)
            .map { _ in false }
    }
    var willEnterForeground:Observable<Bool>{
        return  NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification)
            .map { _ in true }
    }
}
