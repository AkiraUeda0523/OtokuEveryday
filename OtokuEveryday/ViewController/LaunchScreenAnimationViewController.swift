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
        //        setUpTitleImageView()
    }
    // MARK: -
    private func setUpTitleImageView(){
        let imageView = UIImageView(frame: CGRect(x: 87, y: 459, width: 240, height: 128))
        
        imageView.layer.shadowOpacity = 0.3
        imageView.layer.shadowRadius = 3
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOffset = CGSize(width: 5, height: 5)
        
        imageView.image = UIImage(named: "kidou2")
        self.view.addSubview(imageView)
        self.titleImageView = imageView
        
    }
}
