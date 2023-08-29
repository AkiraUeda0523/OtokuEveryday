

import UIKit
import RxSwift
import RxCocoa
import Firebase

struct ScrollModel {
    var title:String
}

final class AutoScrollModel: UIView {
    
    private let autoScrollLabelLayoutArrangeSubject = PublishSubject<AutoScrollModel>()
    private let scrollTitleRelay = BehaviorRelay<[ScrollModel]>(value: [])
    
    private enum AutoScrollDirection {
        case right
        case left
    }
    private enum Const {
        static let labelCount = 2
        static let fadeLength: CGFloat = 7.0
        static let pixelsPerSecond = 45.0
        static let pauseTime = 1.5
    }
    private var labelBufferSpace: CGFloat {
        return self.bounds.size.width
    }
    private var scrolling = false
    private var textAlignment: NSTextAlignment = .left
    private var animationOptions: UIView.AnimationOptions = .curveLinear
    private let scrollDirection: AutoScrollDirection = .left
    private let isScrolling = true
    // UILabel properties
    internal var text: String? {
        get {
            return mainLabel.value(forKey: "text") as? String
        }
        set {
            setText(text: newValue, refresh: true)
        }
    }
    
    internal var attributedText: NSAttributedString? {
        get {
            return mainLabel.attributedText
        }
        set {
            setAttributedText(text: newValue, refresh: true)
        }
    }
    
    private func setText(text: String?, refresh: Bool) {
        // Ignore identical text changes
        guard text != self.text else { return }
        labels.forEach { $0.text = text }
        if refresh {
            refreshLabels()
        }
    }
    
    private func setAttributedText(text: NSAttributedString?, refresh: Bool) {
        guard text != self.attributedText else { return }
        labels.forEach { $0.attributedText = text }
        if refresh {
            refreshLabels()
        }
    }
    
    internal var textColor: UIColor! {
        get {
            return self.mainLabel.textColor
        }
        set {
            labels.forEach { $0.textColor = newValue }
        }
    }
    
    internal var font: UIFont! {
        get {
            return mainLabel.font
        }
        set {
            labels.forEach { $0.font = newValue }
            refreshLabels()
            invalidateIntrinsicContentSize()
        }
    }
    
    internal var shadowColor: UIColor? {
        get {
            return self.mainLabel.shadowColor
        }
        set {
            labels.forEach { $0.shadowColor = newValue }
        }
    }
    
    internal var shadowOffset: CGSize {
        get {
            return self.mainLabel.shadowOffset
        }
        set {
            labels.forEach { $0.shadowOffset = newValue }
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 0.0, height: mainLabel.intrinsicContentSize.height)
    }
    // Views
    private var labels: [UILabel] = {
        var labels = [UILabel]()
        for index in 0 ..< Const.labelCount {
            labels.append(UILabel())
        }
        return labels
    }()
    
    private var mainLabel: UILabel {
        return labels.first ?? UILabel()
    }
    
    lazy private var scrollView: UIScrollView = {
        return UIScrollView(frame: self.bounds).apply { this in
            this.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            this.backgroundColor = .clear
        }
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        addSubview(scrollView)
        // Create the labels
        for index in 0 ..< Const.labelCount {
            labels[index].backgroundColor = .clear
            labels[index].autoresizingMask = autoresizingMask
            scrollView.addSubview(labels[index])
        }
        scrollView.apply { this in
            this.showsVerticalScrollIndicator = false
            this.showsHorizontalScrollIndicator = false
            this.isScrollEnabled = false
        }
        self.isUserInteractionEnabled = false
        self.backgroundColor = .clear
        self.clipsToBounds = true
    }
    
    override var frame: CGRect {
        get {
            return super.frame
        }
        set {
            super.frame = newValue
            didChangeFrame()
        }
    }
    
    override var bounds: CGRect {
        get {
            return super.bounds
        }
        set {
            super.bounds = newValue
            didChangeFrame()
        }
    }
    
    private func didChangeFrame() {
        refreshLabels()
        applyGradientMaskForFadeLength(fadeLengthIn: Const.fadeLength, enableFade: self.scrolling)
    }
    
    internal func observeApplicationNotifications() {
        NotificationCenter.default.apply { this in
            this.removeObserver(self)
            this.addObserver(self, selector: .scrollLabelIfNeeded, name: .willEnterForegroundNotification, object: nil)
            this.addObserver(self, selector: .scrollLabelIfNeeded, name: .didBecomeActiveNotification, object: nil)
        }
    }
    
    private func scrollLabelIfNeededAction() {
        let labelWidth = mainLabel.bounds.width
        guard labelWidth > bounds.width else { return }
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: .scrollLabelIfNeeded, object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: .enableShadow, object: nil)
        scrollView.layer.removeAllAnimations()
        let doScrollLeft = scrollDirection == .left
        scrollView.contentOffset = doScrollLeft ? .zero : CGPoint(x: labelWidth + labelBufferSpace, y: 0)
        self.perform(.enableShadow, with: nil, afterDelay: Const.pauseTime)
        // Animate the scrolling
        let duration = Double(labelWidth) / Const.pixelsPerSecond
        UIView.animate(withDuration: duration,
                       delay: Const.pauseTime,
                       options: [self.animationOptions, UIView.AnimationOptions.allowUserInteraction],
                       animations: { [weak self] () -> Void in
            guard let self = self else { return }
            self.scrollView.contentOffset = doScrollLeft ? CGPoint(x: labelWidth + self.labelBufferSpace, y: 0) : .zero
        }, completion: { [weak self] finished in
            guard let self = self else { return }
            self.scrolling = false
            // Remove the left shadow
            self.applyGradientMaskForFadeLength(fadeLengthIn: Const.fadeLength, enableFade: false)
            // Setup pause delay/loop
            if finished {
                self.performSelector(inBackground: #selector(AutoScrollModel.scrollLabelIfNeeded), with: nil)
            }
        })
    }
    
    private func applyGradientMaskForFadeLength(fadeLengthIn: CGFloat, enableFade fade: Bool) {
        var fadeLength = fadeLengthIn
        let labelWidth = mainLabel.bounds.width
        if labelWidth <= self.bounds.width {
            fadeLength = 0
        }
        if fadeLength != 0 {
            gradientMaskFade(fade: fade)
        } else {
            layer.mask = nil
        }
    }
    
    func gradientMaskFade(fade: Bool) {
        let gradientMask = CAGradientLayer()
        gradientMask.apply { this in
            this.bounds = self.layer.bounds
            this.position = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
            this.shouldRasterize = true
            this.rasterizationScale = UIScreen.main.scale
            this.startPoint = CGPoint(x: 0, y: self.frame.midY)
            this.endPoint = CGPoint(x: 1, y: self.frame.midY)
            // Setup fade mask colors and location
            let transparent = UIColor.black.cgColor
            let opaque = UIColor.black.cgColor
            this.colors = [transparent, opaque, opaque, transparent]
        }
        // Calcluate fade
        let fadePoint = Const.fadeLength / self.bounds.width
        var leftFadePoint = fadePoint
        var rightFadePoint = 1 - fadePoint
        if !fade {
            switch scrollDirection {
            case .left:
                leftFadePoint = 0
            case .right:
                leftFadePoint = 0
                rightFadePoint = 1
            }
        }
        
        // Apply calculations to mask
        gradientMask.locations = [0, NSNumber(value: Double(leftFadePoint)), NSNumber(value: Double(rightFadePoint)), 1]
        // Don't animate the mask change
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.layer.mask = gradientMask
        CATransaction.commit()
    }
    
    private func onUIApplicationDidChangeStatusBarOrientationNotification(notification: NSNotification) {
        // Delay to have it re-calculate on next runloop
        perform(.refreshLabels, with: nil, afterDelay: 0.1)
        perform(.scrollLabelIfNeeded, with: nil, afterDelay: 0.1)
    }
}

private extension AutoScrollModel {
    
    @objc func scrollLabelIfNeeded() {
        guard text != nil && text?.count != 0 else { return }
        DispatchQueue.main.async { [weak self] in
            self?.scrollLabelIfNeededAction()
        }
    }
    
    @objc func refreshLabels() {
        var offset: CGFloat = 0
        labels.forEach {
            $0.sizeToFit()
            var frame = $0.frame
            frame.origin = CGPoint(x: offset, y: 0)
            frame.size.height = bounds.height
            $0.frame = frame
            $0.center = CGPoint(x: $0.center.x, y: round(center.y - self.frame.minY))
            offset += $0.bounds.width + labelBufferSpace
            $0.isHidden = false
        }
        scrollView.contentOffset = .zero
        scrollView.layer.removeAllAnimations()
        // If the label is bigger than the space allocated, then it should scroll
        if mainLabel.bounds.width > bounds.width {
            var size = CGSize(width: 0, height: 0)
            size.width = mainLabel.bounds.width + bounds.width + labelBufferSpace
            size.height = bounds.height
            scrollView.contentSize = size
            applyGradientMaskForFadeLength(fadeLengthIn: Const.fadeLength, enableFade: scrolling)
            scrollLabelIfNeeded()
        } else {
            labels.forEach { $0.isHidden = $0 != mainLabel }
            // Adjust the scroll view and main label
            scrollView.contentSize = bounds.size
            mainLabel.apply { this in
                this.frame = bounds
                this.isHidden = false
                this.textAlignment = textAlignment
            }
            // Cleanup animation
            scrollView.layer.removeAllAnimations()
            applyGradientMaskForFadeLength(fadeLengthIn: 0, enableFade: false)
        }
    }
    
    @objc func enableShadow() {
        scrolling = true
        applyGradientMaskForFadeLength(fadeLengthIn: Const.fadeLength, enableFade: true)
    }
}

private extension Selector {
    static let scrollLabelIfNeeded = #selector(AutoScrollModel.scrollLabelIfNeeded)
    static let refreshLabels = #selector(AutoScrollModel.refreshLabels)
    static let enableShadow = #selector(AutoScrollModel.enableShadow)
}

private extension NSNotification.Name {
    static let willEnterForegroundNotification = UIApplication.willEnterForegroundNotification
    static let didBecomeActiveNotification = UIApplication.didBecomeActiveNotification
}
public protocol Appliable {}

extension Appliable {
    @discardableResult
    public func apply(closure: (_ this: Self) -> Void) -> Self {
        closure(self)
        return self
    }
}
extension NSObject: Appliable {}

//---------------------------------------------------------------------------------------------------------
protocol AutoScrollModelInput{
    func autoScrollLabelLayoutArrange(scrollLabel:AutoScrollModel,scrollBaseViewsBounds:CGRect)->AutoScrollModel
}
protocol AutoScrollModelType {
    var input: AutoScrollModelInput { get }
}
extension AutoScrollModel:AutoScrollModelInput{
    func autoScrollLabelLayoutArrange(scrollLabel:AutoScrollModel,scrollBaseViewsBounds:CGRect)->AutoScrollModel{
        scrollLabel.frame = scrollBaseViewsBounds
        scrollLabel.backgroundColor = .white
        scrollLabel.textColor = .black
        scrollLabel.font = .systemFont(ofSize: 25)
        scrollLabel.observeApplicationNotifications()
        return scrollLabel
    }
}
extension AutoScrollModel:AutoScrollModelType{
    var input: AutoScrollModelInput {
        return self
    }
}
