import UIKit

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
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 3)
        button.layer.shadowOpacity = 0.3
        button.addTarget(self, action: #selector(handleVerifyButton), for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }()

    private let resendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Resend OTP", for: .normal)
        button.setTitleColor(UIColor(hex: "#40CBD8"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        button.addTarget(self, action: #selector(handleResendButton), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#222222")

        [titleLabel, otpStackView, verifyButton, resendButton].forEach {
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

            verifyButton.topAnchor.constraint(equalTo: otpStackView.bottomAnchor, constant: 24),
            verifyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            verifyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            resendButton.topAnchor.constraint(equalTo: verifyButton.bottomAnchor, constant: 16),
            resendButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func createOTPTextField() -> UITextField {
        let textField = UITextField()
        textField.backgroundColor = UIColor(white: 1.0, alpha: 0.7)
        textField.layer.cornerRadius = 12
        textField.textColor = .black
        textField.layer.borderColor = UIColor.gray.cgColor
        textField.layer.borderWidth = 1
        textField.textAlignment = .center
        textField.keyboardType = .numberPad
        textField.font = UIFont.systemFont(ofSize: 18, weight: .bold)

        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)

        return textField
    }

    @objc private func textFieldDidChange(_ textField: UITextField) {
        guard let text = textField.text, text.count == 1 else { return }

        // Move to the next text field
        if let nextField = otpStackView.arrangedSubviews.first(where: { $0 is UITextField && ($0 as! UITextField).text?.isEmpty ?? true }) as? UITextField {
            nextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder() // Dismiss the keyboard if all fields are filled
        }
    }

    @objc private func handleVerifyButton() {
        // Gather OTP from text fields
        let otp = otpStackView.arrangedSubviews.compactMap { ($0 as? UITextField)?.text }.joined()

        // Verify the OTP (Add your logic here)
        print("Entered OTP: \(otp)")
        
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
        present(tabBarController, animated: true, completion: nil)
        
    }

    @objc private func handleResendButton() {
        // Logic to resend OTP
        print("OTP Resent")

        // Show a confirmation to the user
        let alert = UIAlertController(title: nil, message: "OTP has been resent.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

