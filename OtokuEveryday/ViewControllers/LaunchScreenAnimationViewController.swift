//
//  LaunchScreenAnimationViewController.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2021/12/10.
//

import UIKit

class LaunchScreenAnimationViewController: UIViewController {
    @IBOutlet weak var titleImageView: UIImageView!
    // MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTitleImageView()
    }
    // MARK: -
    private func setUpTitleImageView(){
        titleImageView.layer.shadowOpacity = 0.3
        titleImageView.layer.shadowRadius = 3
        titleImageView.layer.shadowColor = UIColor.black.cgColor
        titleImageView.layer.shadowOffset = CGSize(width: 5, height: 5)
        self.titleImageView = UIImageView(frame: CGRect(x: 87, y: 459, width: 240, height: 128))
        titleImageView.image = UIImage(named: "kidou2")
        self.view.addSubview(titleImageView)
    }
}
