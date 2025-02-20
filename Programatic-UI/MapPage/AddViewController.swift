import UIKit

class AddViewController: UIViewController {

    private let newsViewController = NewsViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    private func setupView() {
        view.backgroundColor = UIColor(hex: "#222222")
        
        // Gradient Background
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.black.cgColor, UIColor.systemGray2.cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)

        // Back Button
        let backButton = UIButton()
        let backImage = UIImage(systemName: "chevron.left")
        backButton.setImage(backImage, for: .normal)
        backButton.tintColor = .white
        backButton.layer.cornerRadius = 10
        backButton.clipsToBounds = true
        backButton.addTarget(self, action: #selector(dismissDetailView), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton)

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40)
        ])

        // Add NewsViewController as a Child View Controller
        addChild(newsViewController)
        newsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(newsViewController.view)

        NSLayoutConstraint.activate([
            newsViewController.view.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 10),
            newsViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            newsViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            newsViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        newsViewController.didMove(toParent: self)
    }

    @objc private func dismissDetailView() {
        dismiss(animated: true, completion: nil)
    }
}
