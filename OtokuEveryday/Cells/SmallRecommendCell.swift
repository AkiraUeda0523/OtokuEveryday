//
//
//  RedMoon2021
//
//  Created by 上田晃 on 2022/11/28.
//

import UIKit

public class SmallRecommendCell: UICollectionViewCell {
    var container: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 20
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowRadius = 2
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
        view.backgroundColor = UIColor.rgb(red: 243, green: 243, blue: 243)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    var smallRecommendView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = UIColor.white
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.cornerRadius = 5
        view.layer.shadowOpacity = 0.3
        view.layer.shadowRadius = 2
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    var smallRecommendTitleLabel: UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.numberOfLines = 0
        label.sizeToFit()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    var smallRecommendSubTitleLabel: UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        label.sizeToFit()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(self.container)
        self.container.addSubview(self.smallRecommendView)
        self.container.addSubview(self.smallRecommendTitleLabel)
        self.container.addSubview(self.smallRecommendSubTitleLabel)

        NSLayoutConstraint.activate([
            self.container.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 10),
            self.container.leftAnchor.constraint(equalTo: self.contentView.leftAnchor,constant: 10),
            self.container.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor,constant: 10),
            self.container.rightAnchor.constraint(equalTo: self.contentView.rightAnchor,constant: 10)
        ])

        NSLayoutConstraint.activate([
            self.smallRecommendView.topAnchor.constraint(equalTo: self.container.topAnchor, constant: 10),
            self.smallRecommendView.leftAnchor.constraint(equalTo: self.container.leftAnchor, constant: 10),
            self.smallRecommendView.bottomAnchor.constraint(equalTo: self.container.bottomAnchor, constant: -10),
            self.smallRecommendView.widthAnchor.constraint(equalToConstant: contentView.frame.width / 3),
            self.smallRecommendView.heightAnchor.constraint(equalToConstant: 70)
        ])

        NSLayoutConstraint.activate([
            self.smallRecommendTitleLabel.topAnchor.constraint(equalTo: self.container.topAnchor),
            self.smallRecommendTitleLabel.leftAnchor.constraint(equalTo: self.smallRecommendView.rightAnchor,constant:10),
            self.smallRecommendTitleLabel.rightAnchor.constraint(equalTo: self.container.rightAnchor,constant:-10),
            self.smallRecommendTitleLabel.heightAnchor.constraint(equalToConstant: contentView.frame.height / 2)
        ])

        NSLayoutConstraint.activate([
            self.smallRecommendSubTitleLabel.topAnchor.constraint(equalTo: self.smallRecommendTitleLabel.bottomAnchor),
            self.smallRecommendSubTitleLabel.leftAnchor.constraint(equalTo: self.smallRecommendView.rightAnchor, constant: 10),
            self.smallRecommendSubTitleLabel.rightAnchor.constraint(equalTo: self.container.rightAnchor),
            self.smallRecommendSubTitleLabel.heightAnchor.constraint(equalToConstant: contentView.frame.height / 2)
        ])
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


