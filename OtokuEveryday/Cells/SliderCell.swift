//
//  SliderCell.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2021/11/25.
//

import UIKit

class SliderCell: UICollectionViewCell {
    @IBOutlet weak var SlideImageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    var image: UIImage! {
        didSet {
            SlideImageView.image = image
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        label.layer.cornerRadius = 10
        titleLabel.layer.cornerRadius = 10
        label.clipsToBounds = true
    }
}
