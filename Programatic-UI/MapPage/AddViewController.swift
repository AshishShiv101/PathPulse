import UIKit

class AddViewController: UIViewController {

    private let newsSheet = NewsSheet()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    private func setupView() {
        view.backgroundColor = UIColor(hex: "#222222")
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

        // Add NewsSheet
        newsSheet.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(newsSheet)

        NSLayoutConstraint.activate([
            newsSheet.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 10),
            newsSheet.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            newsSheet.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            newsSheet.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func dismissDetailView() {
        dismiss(animated: true, completion: nil)
    }
}
