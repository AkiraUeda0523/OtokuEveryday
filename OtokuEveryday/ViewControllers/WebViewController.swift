//
//  WebViewController.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2021/09/10.
//

import UIKit
import WebKit
import SDWebImage
import PKHUD
import AudioToolbox

class WebViewController: UIViewController,WKNavigationDelegate {
    @IBOutlet weak var contentView: UIView!
    var otokuEveryDayURL:String? {
        didSet {
        }
    }
    var webView = WKWebView()
    let webConfiguration = WKWebViewConfiguration()
    //    MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpWebView()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        HUD.hide()
    }
    //    MARK: -
    private func setUpWebView(){
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(webView)
        webView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0.0).isActive = true
        webView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0.0).isActive = true
        webView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0.0).isActive = true
        webView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0.0).isActive = true
        webView.load(URLRequest(url: URL(string: otokuEveryDayURL!)!))
    }
    @IBAction func back(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
