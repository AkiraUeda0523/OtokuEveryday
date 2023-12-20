import UIKit

class SplashViewController: UIViewController {
    var splashImageLogo: UIImageView!
    var splashImageTitle: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        splashImageLogo = UIImageView()
        splashImageTitle = UIImageView()
        self.view.backgroundColor = UIColor.white
        setupSplashImageLogo()
        setupSplashImageTitle()
        
        UIView.animate(withDuration: 2.0, delay: 0.0, usingSpringWithDamping: 0.3, initialSpringVelocity: 3.0, options: .curveEaseInOut, animations: {
            self.animateSplashImageLogo()
        }) { _ in
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let storyboard = UIStoryboard(name: "BaseTabBar", bundle: nil)
                let baseTabBarController = storyboard.instantiateViewController(withIdentifier: "map") as! BaseTabBarController
                if let window = UIApplication.shared.windows.first {
                    window.rootViewController = baseTabBarController
                    UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
                }
            }
        }
    }
    
    private func setupSplashImageLogo() {
        splashImageLogo.translatesAutoresizingMaskIntoConstraints = false
        splashImageLogo.image = UIImage(named: "kidou1")
        view.addSubview(splashImageLogo)
        
        NSLayoutConstraint.activate([
            splashImageLogo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            splashImageLogo.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 166),
            splashImageLogo.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
            splashImageLogo.heightAnchor.constraint(equalTo: splashImageLogo.widthAnchor)
        ])
    }
    
    private func setupSplashImageTitle() {
        splashImageTitle.translatesAutoresizingMaskIntoConstraints = false
        splashImageTitle.image = UIImage(named: "kidou2")
        splashImageTitle.contentMode = .scaleAspectFit
        view.addSubview(splashImageTitle)
        NSLayoutConstraint.activate([
            splashImageTitle.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -57),
            splashImageTitle.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 57),
            splashImageTitle.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -45),
            splashImageTitle.widthAnchor.constraint(equalToConstant: 300),
            splashImageTitle.heightAnchor.constraint(equalToConstant: 77)
        ])
    }
    private func animateSplashImageLogo() {
        splashImageLogo.center.y += 50.0
        splashImageLogo.bounds.size.height += 90.0
        splashImageLogo.bounds.size.width += 90.0
    }
}
