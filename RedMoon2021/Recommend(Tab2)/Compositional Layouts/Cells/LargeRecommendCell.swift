//
//  LargeRecommendCell.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2022/11/28.
//
//
import UIKit
import Nuke

class LargeRecommendCell: UICollectionViewCell {
    private var isTouched: Bool = false {
        didSet {
            updateCellAppearance()
        }
    }
    
    var container: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.rgb(red: 243, green: 243, blue: 243)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        return view
    }()
    
    var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var imageView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "nowloading")
        view.backgroundColor = .white
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var highlightOverlay: UIView = {
        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.isHidden = true // 初期状態では非表示
        overlay.layer.cornerRadius = 15
        overlay.layer.masksToBounds = true
        return overlay
    }()
    private var longPressGestureRecognizer: UILongPressGestureRecognizer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLongPressGestureRecognizer() // 長押しジェスチャーを追加
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupLongPressGestureRecognizer()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        setupShadowPath()
    }
    
    private func setupShadowPath() {
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 15).cgPath
    }
    
    private func setupViews() {
        layer.cornerRadius = 15
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 0)
        clipsToBounds = false
        
        container.layer.cornerRadius = 15
        contentView.addSubview(container)
        container.addSubview(imageView)
        container.addSubview(subtitleLabel)
        
        contentView.addSubview(highlightOverlay)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            highlightOverlay.topAnchor.constraint(equalTo: contentView.topAnchor),
            highlightOverlay.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            highlightOverlay.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            highlightOverlay.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: container.heightAnchor, multiplier: 0.7)
        ])
        
        NSLayoutConstraint.activate([
            subtitleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor),
            subtitleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            subtitleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            subtitleLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10)
        ])
        
        imageView.layer.cornerRadius = 15
        imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
    
    private func setupLongPressGestureRecognizer() {
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(_:)))
        longPressGestureRecognizer?.minimumPressDuration = 0.1// 長押しの時間
        longPressGestureRecognizer?.delegate = self
        addGestureRecognizer(longPressGestureRecognizer!)
    }
    
    @objc private func handleLongPressGesture(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            // 長押し開始でハイライトを表示
            isTouched = true
        case .ended, .cancelled:
            // 長押し解除でハイライトを非表示
            isTouched = false
        default:
            break
        }
    }
    
    public func setup(subtitle: String, image: String) {
        self.subtitleLabel.text = subtitle
        let placeholderImage = UIImage(named: "placeholder")
        if let imageURL = URL(string: image) {
            Nuke.loadImage(with: imageURL, options: ImageLoadingOptions(placeholder: placeholderImage, transition: .fadeIn(duration: 0.33)), into: self.imageView)
        } else {
            self.imageView.image = placeholderImage
        }
    }
    
    private func updateCellAppearance() {
        UIView.animate(withDuration: 0.1) {
            self.transform = self.isTouched ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
            self.highlightOverlay.isHidden = !self.isTouched
        }
    }
}

extension LargeRecommendCell: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
