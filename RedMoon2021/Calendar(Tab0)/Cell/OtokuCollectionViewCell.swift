//
//  OtokuCollectionViewCell.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2021/09/12.
//
import UIKit

class OtokuCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var otokuImage: UIImageView!
    @IBOutlet weak var otokuLabel: UILabel!
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupShadow()
        setupImageView()
    }
    required init?(coder: NSCoder) {//💣
        super.init(coder: coder)
        setupShadow()
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        setupImageView()
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        otokuLabel.text = nil
        otokuImage.image = nil
    }
    private func setupImageView() {
        otokuImage.contentMode = .scaleAspectFill
        otokuImage.clipsToBounds = true
    }
    private func setupShadow() {
        layer.applyShadow(color: .black, opacity: 0.8, radius: 8.0, offset: CGSize(width: 0.0, height: 2.0))
    }
}
extension CALayer {
    func applyShadow(color: UIColor, opacity: Float, radius: CGFloat, offset: CGSize) {
        shadowColor = color.cgColor
        shadowOpacity = opacity
        shadowRadius = radius
        shadowOffset = offset
    }
}
