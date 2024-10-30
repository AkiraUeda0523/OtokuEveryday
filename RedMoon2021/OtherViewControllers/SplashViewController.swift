import UIKit

class SplashViewController: UIViewController {
    // スプラッシュ画面のロゴとタイトル用のUIImageViewを定義
    var splashImageLogo: UIImageView!
    var splashImageTitle: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // UIImageViewのインスタンスを生成
        splashImageLogo = UIImageView()
        splashImageTitle = UIImageView()
        // 背景色を白に設定
        self.view.backgroundColor = UIColor.white
        // ロゴとタイトルのセットアップメソッドを呼び出し
        setupSplashImageLogo()
        setupSplashImageTitle()
        // アニメーションを実行
        UIView.animate(withDuration: 2.0, delay: 0.0, usingSpringWithDamping: 0.3, initialSpringVelocity: 3.0, options: .curveEaseInOut, animations: {
            self.animateSplashImageLogo()  // ロゴのアニメーション
        }) { _ in
            // アニメーション完了後に実行
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // ストーリーボードからBaseTabBarControllerのインスタンスを作成
                let storyboard = UIStoryboard(name: "BaseTabBar", bundle: nil)
                let baseTabBarController = storyboard.instantiateViewController(withIdentifier: "map") as! BaseTabBarController
                // ウィンドウのルートビューコントローラを変更
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController = baseTabBarController
                    UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
                }

            }
        }
    }
    // ロゴのセットアップ
    private func setupSplashImageLogo() {
        splashImageLogo.translatesAutoresizingMaskIntoConstraints = false
        splashImageLogo.image = UIImage(named: "kidou1")  // ロゴ画像を設定
        view.addSubview(splashImageLogo)
        // 制約を設定
        NSLayoutConstraint.activate([
            splashImageLogo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            splashImageLogo.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 166),
            splashImageLogo.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),  // 画面幅の60%
            splashImageLogo.heightAnchor.constraint(equalTo: splashImageLogo.widthAnchor)  // アスペクト比1:1
        ])
    }
    // タイトルのセットアップ
    private func setupSplashImageTitle() {
        splashImageTitle.translatesAutoresizingMaskIntoConstraints = false
        splashImageTitle.image = UIImage(named: "kidou2")  // タイトル画像を設定
        splashImageTitle.contentMode = .scaleAspectFit  // アスペクトフィットに設定
        view.addSubview(splashImageTitle)
        // 制約を設定
        NSLayoutConstraint.activate([
            splashImageTitle.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -57),
            splashImageTitle.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 57),
            splashImageTitle.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -45),
            splashImageTitle.widthAnchor.constraint(equalToConstant: 300),
            splashImageTitle.heightAnchor.constraint(equalToConstant: 77)
        ])
    }
    // ロゴのアニメーションを定義
    private func animateSplashImageLogo() {
        splashImageLogo.center.y += 50.0  // Y軸に沿って移動
        splashImageLogo.bounds.size.height += 90.0  // 高さを増加
        splashImageLogo.bounds.size.width += 90.0  // 幅を増加
    }
}
