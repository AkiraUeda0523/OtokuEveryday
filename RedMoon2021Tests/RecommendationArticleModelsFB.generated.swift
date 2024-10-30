// Generated using Sourcery 2.1.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// RecommendationArticleModelMock.stencil

import Foundation
@testable import RedMoon2021

// sourcery:begin: autoMockable
protocol RecommendationArticleModelFirebase {
    func fetchRecommendData(completion: @escaping ([RecommendModel]?, Error?) -> Void)
    func fetchRecommendTitle(completion: @escaping ([RecomendTitleModel]?, Error?) -> Void)
}
// sourcery:end

// sourcery:inline:RecommendationArticleModelFirebase.Mock
class MockRecommendationArticleModelFirebase: RecommendationArticleModelFirebase {
    var fetchRecommendDataCallsCount = 0
    var fetchRecommendDataCompletionReturnValue: ([RecommendModel]?, Error?)!
    var fetchRecommendTitleCallsCount = 0
    var fetchRecommendTitleCompletionReturnValue: ([RecomendTitleModel]?, Error?)!

    func fetchRecommendData(completion: @escaping ([RecommendModel]?, Error?) -> Void) {
        fetchRecommendDataCallsCount += 1
        completion(fetchRecommendDataCompletionReturnValue.0, fetchRecommendDataCompletionReturnValue.1)
    }

    func fetchRecommendTitle(completion: @escaping ([RecomendTitleModel]?, Error?) -> Void) {
        fetchRecommendTitleCallsCount += 1
        completion(fetchRecommendTitleCompletionReturnValue.0, fetchRecommendTitleCompletionReturnValue.1)
    }
}
// sourcery:end

