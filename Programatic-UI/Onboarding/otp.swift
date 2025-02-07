import UIKit
import FirebaseAuth

class OTPPage: UIViewController {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter OTP"
        label.font = UIFont.boldSystemFont(ofSize: 28)
        label.textColor = UIColor(hex: "#F2F1F1")
        label.textAlignment = .center
        return label
    }()

    private lazy var otpStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 12

        for _ in 0..<6 {
            let textField = createOTPTextField()
            stackView.addArrangedSubview(textField)
        }
        return stackView
    }()

    private let verifyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Verify", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.backgroundColor = UIColor(hex: "#40CBD8")
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(handleVerifyButton), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#222222")

        [titleLabel, otpStackView, verifyButton].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 180),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            otpStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            otpStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            otpStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            otpStackView.heightAnchor.constraint(equalToConstant: 50),

            verifyButton.topAnchor.constraint(equalTo: otpStackView.bottomAnchor, constant: 30),
            verifyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            verifyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func createOTPTextField() -> UITextField {
        let textField = UITextField()
        textField.backgroundColor = UIColor(white: 1.0, alpha: 0.7)
        textField.layer.cornerRadius = 12
        textField.textColor = .black
        textField.textAlignment = .center
        textField.keyboardType = .numberPad
        textField.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        return textField
    }

    @objc private func textFieldDidChange(_ textField: UITextField) {
        guard let text = textField.text, text.count == 1 else { return }
        if let nextField = otpStackView.arrangedSubviews.first(where: { ($0 as? UITextField)?.text?.isEmpty ?? true }) as? UITextField {
            nextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
    }

    @objc private func handleVerifyButton() {
        let otp = otpStackView.arrangedSubviews.compactMap { ($0 as? UITextField)?.text }.joined()

        guard otp.count == 6, let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") else {
            showAlert(message: "Invalid OTP.")
            return
        }

        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: otp)
        
        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                self.showAlert(message: error.localizedDescription)
                return
            }
            
            print("OTP Verified Successfully!")

            // Setting up the TabBarController
            let mapPage = MapPage()
            mapPage.tabBarItem = UITabBarItem(title: "Map", image: UIImage(systemName: "map.fill"), tag: 0)

            let guidePage = GuidePage()
            guidePage.tabBarItem = UITabBarItem(title: "Guide", image: UIImage(systemName: "bookmark.fill"), tag: 1)
            let guideNavigationController = UINavigationController(rootViewController: guidePage)

            let accountPage = AccountPage()
            accountPage.tabBarItem = UITabBarItem(title: "Account", image: UIImage(systemName: "person.crop.circle"), tag: 2)
            let accNav = UINavigationController(rootViewController: accountPage)

            let tabBarController = UITabBarController()
            tabBarController.viewControllers = [mapPage, guideNavigationController, accNav]

            if #available(iOS 15.0, *) {
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(hex: "#333333")
                appearance.stackedLayoutAppearance.selected.iconColor = UIColor(hex: "#40cbd8")
                appearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(hex: "#40cbd8")]
                appearance.stackedLayoutAppearance.normal.iconColor = .white
                appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]

                tabBarController.tabBar.standardAppearance = appearance
                tabBarController.tabBar.scrollEdgeAppearance = appearance
            } else {
                tabBarController.tabBar.barTintColor = UIColor(hex: "#151515")
                tabBarController.tabBar.tintColor = UIColor(hex: "#40cbd8")
                tabBarController.tabBar.unselectedItemTintColor = .white
            }

            tabBarController.modalPresentationStyle = .fullScreen
            self.present(tabBarController, animated: true, completion: nil)
        }
    }


    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
