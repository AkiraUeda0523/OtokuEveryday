import UIKit

public class SmallRecommendCell: UICollectionViewCell {
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
    
    var smallRecommendView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "nowloading")
        view.backgroundColor = UIColor.white
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var smallRecommendTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var smallRecommendSubTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        setupShadowPath()
    }

    private func setupShadowPath() {
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 20).cgPath
    }

    private func setupViews() {
        layer.cornerRadius = 20
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 10)
        clipsToBounds = false
        
        container.layer.cornerRadius = 20
        contentView.addSubview(container)
        container.addSubview(smallRecommendView)
        container.addSubview(smallRecommendTitleLabel)
        container.addSubview(smallRecommendSubTitleLabel)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            smallRecommendView.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            smallRecommendView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            smallRecommendView.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 1/3),
            smallRecommendView.heightAnchor.constraint(lessThanOrEqualTo: smallRecommendView.widthAnchor),
            smallRecommendView.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -10)
        ])

        NSLayoutConstraint.activate([
            smallRecommendTitleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            smallRecommendTitleLabel.leadingAnchor.constraint(equalTo: smallRecommendView.trailingAnchor, constant: 10),
            smallRecommendTitleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            smallRecommendTitleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 20)
        ])

        NSLayoutConstraint.activate([
            smallRecommendSubTitleLabel.topAnchor.constraint(equalTo: smallRecommendTitleLabel.bottomAnchor, constant: 5),
            smallRecommendSubTitleLabel.leadingAnchor.constraint(equalTo: smallRecommendView.trailingAnchor, constant: 10),
            smallRecommendSubTitleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            smallRecommendSubTitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -10),
            smallRecommendSubTitleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 20)
        ])
    }
    
    private func updateCellAppearance() {
        UIView.animate(withDuration: 0.2) {
            self.transform = self.isTouched ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
        }
    }
}

extension SmallRecommendCell: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
