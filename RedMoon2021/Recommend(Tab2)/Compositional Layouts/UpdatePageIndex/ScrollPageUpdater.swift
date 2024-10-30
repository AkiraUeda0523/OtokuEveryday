import UIKit
import AudioToolbox
// MARK: -
protocol PageUpdater {
    func LargeSectionPageUpdater(for section: Int,recommendationArticleViewModel: RecommendationArticleViewModelType, recommendViewBounds: CGRect, updatePageIndex: @escaping (Int) -> Void) -> NSCollectionLayoutSection
    func SmallSectionPageUpdater(for section: Int, recommendationArticleViewModel: RecommendationArticleViewModelType, recommendViewBounds: CGRect, updatePageIndex: @escaping (Int) -> Void) -> NSCollectionLayoutSection
    func DefaultSectionLayout(for section: Int, recommendViewBounds: CGRect) -> NSCollectionLayoutSection
}
// MARK: -
final class ScrollPageUpdater: PageUpdater {
    let layoutBuilder = LayoutBuilder()
    var previousOffsets: [Int: CGPoint] = [:]
    // MARK: -
    func LargeSectionPageUpdater(for section: Int, recommendationArticleViewModel: RecommendationArticleViewModelType, recommendViewBounds: CGRect, updatePageIndex: @escaping (Int) -> Void) -> NSCollectionLayoutSection {
        let sectionLayout = layoutBuilder.buildLargeHorizontalSectionWithFooter(recommendViewBounds: recommendViewBounds)
        let offsetThreshold: CGFloat = 1.0
        if previousOffsets[section] == nil {
            previousOffsets[section] = .zero
        }
        // タイマーとスクロール状態を保持する変数を追加
        var scrollStopTimer: Timer?
        sectionLayout.visibleItemsInvalidationHandler = { [weak self] visibleItems, offset, _ in
            guard let self = self, !visibleItems.isEmpty else { return }
            let previousOffset = self.previousOffsets[section] ?? .zero
            // 縦方向のスクロールイベントを完全に無視
            if abs(offset.y - previousOffset.y) > offsetThreshold {
                self.previousOffsets[section]?.y = offset.y
                return
            }
            // 横方向のオフセットの変化が小さい場合は無視
            if abs(offset.x - previousOffset.x) <= offsetThreshold {
                return
            }
            // 横スクロールのみでタイマーを再生成
            scrollStopTimer?.invalidate()
            scrollStopTimer = Timer.scheduledTimer(withTimeInterval: 0.100, repeats: false) { _ in
                // スクロールが停止したと判断（横スクロールのみを対象）
                recommendationArticleViewModel.input.largeSectionisScrollingObserver.onNext(())
            }
            // ページインデックスの更新
            let centerOffset = offset.x + recommendViewBounds.width / 2
            let closestItem = visibleItems.min(by: {
                abs($0.frame.midX - centerOffset) < abs($1.frame.midX - centerOffset)
            })
            let closestItemIndex = closestItem?.indexPath.item ?? 0
            updatePageIndex(closestItemIndex)
            // 前回のオフセットを更新（横方向のみ）
            self.previousOffsets[section] = offset
        }
        return sectionLayout
    }
    // MARK: -
    internal func SmallSectionPageUpdater(for section: Int, recommendationArticleViewModel: RecommendationArticleViewModelType, recommendViewBounds: CGRect, updatePageIndex: @escaping (Int) -> Void) -> NSCollectionLayoutSection {
        let sectionLayout = layoutBuilder.buildSmallHorizontalSectionWithFooter(recommendViewBounds: recommendViewBounds)
        let offsetThreshold: CGFloat = 10.0 // 微小な変化を無視するためのしきい値
        if previousOffsets[section] == nil {
            previousOffsets[section] = .zero
        }
        var scrollStopTimer: Timer?
        sectionLayout.visibleItemsInvalidationHandler = { [weak self] visibleItems, offset, _ in
            guard let self = self, !visibleItems.isEmpty else { return }
            let previousOffset = self.previousOffsets[section] ?? .zero
            // 縦方向のスクロールイベントを完全に無視
            if abs(offset.y - previousOffset.y) > offsetThreshold {
                self.previousOffsets[section]?.y = offset.y
                return
            }
            // 横方向のオフセットの変化が小さい場合は無視
            if abs(offset.x - previousOffset.x) <= offsetThreshold {
                return
            }
            // 横スクロールのみでタイマーを再生成
            scrollStopTimer?.invalidate()
            scrollStopTimer = Timer.scheduledTimer(withTimeInterval: 0.100, repeats: false) { _ in
                // スクロールが停止したと判断（横スクロールのみを対象）
                recommendationArticleViewModel.input.smallSectionScrollingObserver.onNext(())
            }
            // ページインデックスの更新
            let centerOffset = offset.x + recommendViewBounds.width / 2
            let closestItem = visibleItems.min(by: {
                abs($0.frame.midX - centerOffset) < abs($1.frame.midX - centerOffset)
            })?.indexPath.item ?? 0
            let closestGroupIndex = closestItem / 3
            updatePageIndex(closestGroupIndex)
            // 前回のオフセットを更新（横方向のみ）
            self.previousOffsets[section] = offset
        }
        return sectionLayout
    }
    // MARK: -
    internal func DefaultSectionLayout(for section: Int, recommendViewBounds: CGRect) -> NSCollectionLayoutSection {
        return layoutBuilder.buildSmallHorizontalSectionWithFooter(recommendViewBounds: recommendViewBounds)
    }
}
