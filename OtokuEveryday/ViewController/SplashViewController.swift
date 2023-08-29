//
//  SplashViewController.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2022/02/05.
//

import UIKit
class SplashViewController: UIViewController {
    @IBOutlet weak var splashImageLogo: UIImageView!
    @IBOutlet weak var splashImageTitle: UIImageView!
    // MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        UIView.animate(withDuration: 2.0, delay: 0.0, usingSpringWithDamping: 0.3, initialSpringVelocity: 3.0, options: .curveEaseInOut, animations: { [self] in
            setUpSplashImageLogo()
        })
    }
    override func viewDidAppear(_ animated: Bool) {
        sleep(2)
        let baseVC = self.storyboard?.instantiateViewController(identifier: "map") as! BaseTabBarController
        self.navigationController!.navigationBar.isHidden = true
        self.navigationController?.pushViewController(baseVC, animated: true)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    // MARK: -
    private func setUpSplashImageLogo(){
        splashImageLogo.center.y += 50.0
        splashImageLogo.bounds.size.height += 90.0
        splashImageLogo.bounds.size.width += 90.0
    }
}
