//
//  CategoryViewController.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2021/11/18.

import UIKit
import ViewAnimator
import AudioToolbox
import SafariServices

class CategoryViewController: UIViewController {
    
    @IBOutlet weak var otherOtokuTableView: UITableView!
    var otokuArray = ["新着記事","フード","レジャー","ビューティ","サブスク","ビジネス","エブ子のお得日記"]
    var imageArray = ["0","1","2","3","4","5","6"]
    private var otokuSelectedWeb:String = ""
    // MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()
        otherOtokuTableView.delegate = self
        otherOtokuTableView.dataSource = self
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.backgroundColor = .systemRed
        let animation = [AnimationType.vector(CGVector(dx: 0, dy: 30))]
        UIView.animate(views: otherOtokuTableView.visibleCells, animations: animation, completion:nil)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
}
// MARK: -
extension CategoryViewController:UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return otokuArray.count
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! OtherOtokuCustomCell
        cell.otherOtokuImage.image = UIImage(named: imageArray[indexPath.row])
        cell.otherOtokuLabel.text = otokuArray[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        AudioServicesPlaySystemSound(1519)
        
        switch indexPath.row {
        case 0:
            let url = URL(string:"https://otoku-everyday.com/category/new/")
            let safariView = SFSafariViewController(url: url!)
            present(safariView, animated: true)
        case 1:
            let url = URL(string:"https://otoku-everyday.com/category/food/")
            let safariView = SFSafariViewController(url: url!)
            present(safariView, animated: true)
        case 2:
            let url = URL(string:"https://otoku-everyday.com/category/leisure/")
            let safariView = SFSafariViewController(url: url!)
            present(safariView, animated: true)
        case 3:
            let url = URL(string:"https://otoku-everyday.com/category/beauty/")
            let safariView = SFSafariViewController(url: url!)
            present(safariView, animated: true)
        case 4:
            let url = URL(string:"https://otoku-everyday.com/category/subscription/")
            let safariView = SFSafariViewController(url: url!)
            present(safariView, animated: true)
        case 5:
            let url = URL(string:"https://otoku-everyday.com/category/business/")
            let safariView = SFSafariViewController(url: url!)
            present(safariView, animated: true)
        case 6:
            let url = URL(string:"https://otoku-everyday.com/category/blogdeotoku/")
            let safariView = SFSafariViewController(url: url!)
            present(safariView, animated: true)
        default:
            let url = URL(string:"https://otoku-everyday.com/category/blogdeotoku/")
            let safariView = SFSafariViewController(url: url!)
            present(safariView, animated: true)
        }
    }
}




