//
//  LargeRecommendCell.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2022/11/28.
//

import UIKit
import SDWebImage
import AlamofireImage


public class LargeRecommendCell: UICollectionViewCell {

    var container: UIView = {
        let view = UIView()
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.cornerRadius = 7.5
        view.layer.shadowOpacity = 0.3
        view.layer.shadowRadius = 10
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
        view.backgroundColor = UIColor.rgb(red: 243, green: 243, blue: 243)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    var titleLabel: UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .headline).withSize(26)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var subtitleLabel: UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var imageView: UIImageView = {
        let view: UIImageView = UIImageView()
        view.image = UIImage(named: "MAP")
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowRadius = 10
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
        view.layer.cornerRadius = 7.5
        view.backgroundColor = .white
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(self.container)
        self.container.addSubview(self.imageView)
        self.container.addSubview(self.subtitleLabel)

        NSLayoutConstraint.activate([
            self.container.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.container.leftAnchor.constraint(equalTo: self.contentView.leftAnchor),
            self.container.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            self.container.rightAnchor.constraint(equalTo: self.contentView.rightAnchor)
        ])

        NSLayoutConstraint.activate([
            self.imageView.topAnchor.constraint(equalTo: self.container.topAnchor, constant: 0),
            self.imageView.leftAnchor.constraint(equalTo: self.container.leftAnchor, constant: 0),
            self.imageView.rightAnchor.constraint(equalTo: self.container.rightAnchor, constant: 0),
            self.imageView.bottomAnchor.constraint(equalTo: self.container.bottomAnchor, constant: -50),
        ])

        NSLayoutConstraint.activate([
            self.subtitleLabel.topAnchor.constraint(equalTo: self.imageView.bottomAnchor, constant: 0),
            self.subtitleLabel.leftAnchor.constraint(equalTo: self.container.leftAnchor, constant: 0),
            self.subtitleLabel.bottomAnchor.constraint(equalTo: self.container.bottomAnchor, constant: 0),
            self.subtitleLabel.rightAnchor.constraint(equalTo: self.container.rightAnchor, constant: 0)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setup(title: String, subtitle: String,image:String) {
        self.subtitleLabel.text = subtitle
        self.imageView.sd_setImage(with: URL(string: image), completed: nil)
    }
}



