//
//  RecommendationArticleViewModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2023/01/10.
//

import Foundation
import RxSwift
import RxRelay
import MapKit
import GoogleMobileAds
import FirebaseFirestore

protocol RecommendationArticleViewModelOutput {
    var RecommendationArticleViewModelObservable:Observable<[RecommendModel]> { get }
    var RecommendationArticleViewModelTitleObservable:Observable<[RecomendTitleModel]> { get }
}
protocol RecommendationArticleViewModelInput {
    var fetchRecommendDataTitleTriggerObserver:AnyObserver<Void> { get }
}
protocol RecommendationArticleViewModelType {
    var output: RecommendationArticleViewModelOutput { get }
    var input: RecommendationArticleViewModelInput { get }
}

final class  RecommendationArticleViewModel{
    let disposeBag = DisposeBag()
    let RecommendationArticleViewModelRelay = BehaviorRelay<[RecommendModel]>(value: [])
    let RecommendationArticleViewModelTitleRelay = BehaviorRelay<[RecomendTitleModel]>(value: [])
    let recommendationArticleModel: RecommendationArticleModelType
    var fetchRecommendDataTitleTrigger = PublishSubject<Void>()
    init(model: RecommendationArticleModelType) {
        recommendationArticleModel = model
        
        recommendationArticleModel
            .output
            .recommendDataObservable
            .subscribe { [self] data in
                RecommendationArticleViewModelRelay.accept(data)
            }
            .disposed(by: disposeBag)
        
        recommendationArticleModel
            .output
            .recommendTitleObservable
            .subscribe { [self] title in
                RecommendationArticleViewModelTitleRelay.accept(title)
            }
            .disposed(by: disposeBag)
        
        fetchRecommendDataTitleTrigger
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.recommendationArticleModel.input.fetchRecommendData()
                self.recommendationArticleModel.input.fetchRecommendTitle()
            })
            .disposed(by: disposeBag)
        
    }
}
extension RecommendationArticleViewModel: RecommendationArticleViewModelOutput {
    var RecommendationArticleViewModelObservable: RxSwift.Observable<[RecommendModel]> {
        RecommendationArticleViewModelRelay.asObservable()
    }
    var RecommendationArticleViewModelTitleObservable: RxSwift.Observable<[RecomendTitleModel]> {
        RecommendationArticleViewModelTitleRelay.asObservable()
    }
}
extension RecommendationArticleViewModel: RecommendationArticleViewModelInput {
    var fetchRecommendDataTitleTriggerObserver: RxSwift.AnyObserver<Void> {
        fetchRecommendDataTitleTrigger.asObserver()
    }
}
extension RecommendationArticleViewModel: RecommendationArticleViewModelType {
    var output: RecommendationArticleViewModelOutput { return self }
    var input: RecommendationArticleViewModelInput { return self }
}
