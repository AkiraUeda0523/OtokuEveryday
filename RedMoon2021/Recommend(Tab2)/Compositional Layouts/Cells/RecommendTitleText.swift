//  RedMoon2021
//
//  Created by 上田晃 on 2022/11/28.
//
import UIKit

public class RecommendTitleText: UICollectionViewCell {
    var container: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.rgb(red: 243, green: 243, blue: 243)
        view.layer.borderColor = CGColor(red: 20, green: 20, blue: 20, alpha: 1)
        view.layer.cornerRadius = 5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    var recommendLabel: UILabel = {
        let label: UILabel = UILabel()
        label.textAlignment = NSTextAlignment.center
        var font = UIFont(name: "ヒラギノ丸ゴ ProN", size: 20)
        font = UIFont.boldSystemFont(ofSize: 20)
        label.font = font
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(self.container)
        self.container.addSubview(self.recommendLabel)
        NSLayoutConstraint.activate([
            self.container.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.container.leftAnchor.constraint(equalTo: self.contentView.leftAnchor),
            self.container.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            self.container.rightAnchor.constraint(equalTo: self.contentView.rightAnchor)
        ])
        NSLayoutConstraint.activate([
            self.recommendLabel.topAnchor.constraint(equalTo: self.container.topAnchor),
            self.recommendLabel.leftAnchor.constraint(equalTo: self.container.leftAnchor),
            self.recommendLabel.bottomAnchor.constraint(equalTo: self.container.bottomAnchor),
            self.recommendLabel.rightAnchor.constraint(equalTo: self.container.rightAnchor)
        ])
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
