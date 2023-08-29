import UIKit
import Nuke

class SliderCell: UICollectionViewCell {
    @IBOutlet weak var slideImageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    let defaultImage = UIImage(named: "nowloading")
    var imageURL: URL! {
        didSet {
            var options = ImageLoadingOptions(placeholder: defaultImage, transition: .fadeIn(duration: 0.33))
            options.contentModes?.success = .scaleAspectFill
            options.contentModes?.failure = .scaleAspectFit
            options.contentModes?.placeholder = .scaleAspectFit
            Nuke.loadImage(with: imageURL, options: options, into: slideImageView, completion: { [weak self] _ in
                if self?.slideImageView.image == self?.defaultImage {
                    self?.slideImageView.contentMode = .scaleAspectFit
                } else {
                    self?.slideImageView.contentMode = .scaleAspectFill
                }
            })
        }
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        slideImageView.image = defaultImage
        slideImageView.contentMode = .scaleAspectFill
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        label.layer.cornerRadius = 10
        titleLabel.layer.cornerRadius = 10
        label.clipsToBounds = true
        slideImageView.image = defaultImage
    }
}
