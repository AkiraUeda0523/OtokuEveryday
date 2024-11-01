// Generated using Sourcery 2.1.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// sourcery:inline:CalendarViewModelInput.Mock
class CalendarViewModelInputMock: CalendarViewModelInput {
    var calendarSelectedDateObserverReturnValue: AnyObserver<Date>!
    var viewWidthSizeObserverReturnValue: AnyObserver<SetAdMobModelData>!
    var collectionViewSelectedIndexPathObserverReturnValue: AnyObserver<IndexPath>!
    var scrollBaseViewsBoundsObservableReturnValue: AnyObserver<CGRect>!

    // sourcery:begin: CalendarViewModelInput
    var calendarSelectedDateObserver: AnyObserver<Date> {
        return calendarSelectedDateObserverReturnValue
    }
    var viewWidthSizeObserver: AnyObserver<SetAdMobModelData> {
        return viewWidthSizeObserverReturnValue
    }
    var collectionViewSelectedIndexPathObserver: AnyObserver<IndexPath> {
        return collectionViewSelectedIndexPathObserverReturnValue
    }
    var scrollBaseViewsBoundsObservable: AnyObserver<CGRect> {
        return scrollBaseViewsBoundsObservableReturnValue
    }
    // sourcery:end
}
// sourcery:endinline

// sourcery:inline:CalendarViewModelOutput.Mock
class CalendarViewModelOutputMock: CalendarViewModelOutput {
    var showableInfosObservableReturnValue: Observable<[OtokuDataModel]>!
    var authStateObservableReturnValue: Observable<AuthStatus>!
    var isLoadingObservableReturnValue: Observable<Bool>!
    var setAdMobBannerObservableReturnValue: Observable<GADBannerView>!
    var collectionViewSelectedUrlObservableReturnValue: Observable<String>!
    var autoScrollModelObservableReturnValue: Observable<AutoScrollModel>!

    // sourcery:begin: CalendarViewModelOutput
    var showableInfosObservable: Observable<[OtokuDataModel]> {
        return showableInfosObservableReturnValue
    }
    var authStateObservable: Observable<AuthStatus> {
        return authStateObservableReturnValue
    }
    var isLoadingObservable: Observable<Bool> {
        return isLoadingObservableReturnValue
    }
    var setAdMobBannerObservable: Observable<GADBannerView> {
        return setAdMobBannerObservableReturnValue
    }
    var collectionViewSelectedUrlObservable: Observable<String> {
        return collectionViewSelectedUrlObservableReturnValue
    }
    var autoScrollModelObservable: Observable<AutoScrollModel> {
        return autoScrollModelObservableReturnValue
    }
    // sourcery:end
}
// sourcery:endinline

// sourcery:inline:CalendarViewModelType.Mock
class CalendarViewModelTypeMock: CalendarViewModelType {
    var inputReturnValue: CalendarViewModelInputMock!
    var outputReturnValue: CalendarViewModelOutputMock!

    // sourcery:begin: CalendarViewModelType
    var input: CalendarViewModelInput {
        return inputReturnValue
    }
    var output: CalendarViewModelOutput {
        return outputReturnValue
    }
    // sourcery:end
}
// sourcery:endinline




