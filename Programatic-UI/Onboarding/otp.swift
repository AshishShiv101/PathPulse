import UIKit
import FirebaseAuth

class OTPPage: UIViewController {
     
    private let logoStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let pathLabel = UILabel()
        pathLabel.text = "Path"
        pathLabel.font = UIFont.boldSystemFont(ofSize: 40)
        pathLabel.textColor = UIColor(hex: "40CBD8")
        
        let pulseLabel = UILabel()
        pulseLabel.text = "Pulse"
        pulseLabel.font = UIFont.systemFont(ofSize: 40, weight: .light)
        pulseLabel.textColor = .white
        
        stackView.addArrangedSubview(pathLabel)
        stackView.addArrangedSubview(pulseLabel)
        return stackView
    }()
    private let taglineLabel: UILabel = {
            let label = UILabel()
            label.text = "Stay ahead, Stay safe"
            label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            label.textColor = .gray
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
    private let roadImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "road.lanes.curved.right"))
        imageView.tintColor = UIColor(hex: "40CBD8")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let logoStackContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = -25
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#333333")
        view.layer.cornerRadius = 30
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter OTP"
        label.font = UIFont.boldSystemFont(ofSize: 28)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    private let resendButton: UIButton = {
            let button = UIButton(type: .system)
            button.setTitle("Resend OTP", for: .normal)
            button.setTitleColor(UIColor(hex: "#40CBD8"), for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            button.backgroundColor = .clear
            button.addTarget(self, action: #selector(handleResendOTP), for: .touchUpInside)
            return button
        }()
    
    private let changeNumberButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Change Number", for: .normal)
        button.setTitleColor(.gray, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(handleChangeNumber), for: .touchUpInside)
        return button
    }()
    @objc private func handleChangeNumber() {
            UserDefaults.standard.removeObject(forKey: "authVerificationID")
            UserDefaults.standard.removeObject(forKey: "phoneNumber")
            
            let loginPage = LoginPage()
            let navigationController = UINavigationController(rootViewController: loginPage)
            navigationController.modalPresentationStyle = .fullScreen
                        present(navigationController, animated: true, completion: nil)
        }
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Please enter the verification code sent to your phone"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .gray
        label.textAlignment = .center
        label.numberOfLines = 0
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
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.backgroundColor = UIColor(hex: "#40CBD8")
        button.layer.cornerRadius = 12
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.addTarget(self, action: #selector(handleVerifyButton), for: .touchUpInside)
        return button
    }()

    private let buttonStackView: UIStackView = {
            let stackView = UIStackView()
            stackView.axis = .vertical
            stackView.alignment = .center
            stackView.spacing = 16
            stackView.translatesAutoresizingMaskIntoConstraints = false
            return stackView
        }()

        override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()
            setupGradientBackground()
            navigationItem.hidesBackButton = true
        }

    private func setupGradientBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        
        let topColor = UIColor(hex: "#222222").cgColor
        let bottomColor = UIColor(hex: "#1A1A1A").cgColor
        
        gradientLayer.colors = [topColor, bottomColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#222222")
            
        // Clear and set up logo stack container in correct order
        logoStackContainer.removeArrangedSubview(logoStack)
        logoStackContainer.removeArrangedSubview(taglineLabel)
        logoStackContainer.removeArrangedSubview(roadImageView)
        
        // Add elements in new order - logo, road image, then tagline
        logoStackContainer.addArrangedSubview(logoStack)
        logoStackContainer.addArrangedSubview(roadImageView)
        logoStackContainer.addArrangedSubview(taglineLabel)
        
        // Adjust spacing for new layout
        logoStackContainer.setCustomSpacing(-25, after: logoStack) // Space between logo and road
        logoStackContainer.setCustomSpacing(8, after: roadImageView) // Space between road and tagline
        
        // Update tagline appearance for better visibility
        taglineLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        taglineLabel.textColor = .gray
        
        // Rest of the setup remains the same
        view.addSubview(logoStackContainer)
        view.addSubview(cardView)
        
        // Set up button stack
        buttonStackView.addArrangedSubview(resendButton)
        buttonStackView.addArrangedSubview(changeNumberButton)
        
        // Add all elements to card view
        [titleLabel, subtitleLabel, otpStackView, verifyButton, buttonStackView].forEach {
            cardView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            logoStackContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            logoStackContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            roadImageView.widthAnchor.constraint(equalToConstant: 100),
            roadImageView.heightAnchor.constraint(equalToConstant: 100),
            
            cardView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.50),
            cardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 30),
            titleLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),

            otpStackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 30),
            otpStackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            otpStackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            otpStackView.heightAnchor.constraint(equalToConstant: 50),

            verifyButton.topAnchor.constraint(equalTo: otpStackView.bottomAnchor, constant: 30),
            verifyButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            verifyButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            
            buttonStackView.topAnchor.constraint(equalTo: verifyButton.bottomAnchor, constant: 24),
            buttonStackView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            buttonStackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            buttonStackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24)
        ])
    }

    private func createOTPTextField() -> UITextField {
        let textField = UITextField()
        textField.backgroundColor = UIColor(white: 1.0, alpha: 0.9)
        textField.layer.cornerRadius = 12
        textField.textColor = .black
        textField.textAlignment = .center
        textField.keyboardType = .numberPad
        textField.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.layer.borderWidth = 1
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

    @objc private func handleResendOTP() {
            resendButton.isEnabled = false
            
            // Start countdown timer (60 seconds)
            var timeRemaining = 60
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                
                timeRemaining -= 1
                if timeRemaining > 0 {
                    self.resendButton.setTitle("Resend OTP (\(timeRemaining)s)", for: .normal)
                } else {
                    timer.invalidate()
                    self.resendButton.setTitle("Resend OTP", for: .normal)
                    self.resendButton.isEnabled = true
                }
            }
            
            // Resend OTP logic here
            guard let phoneNumber = UserDefaults.standard.string(forKey: "phoneNumber") else {
                showAlert(message: "Phone number not found")
                return
            }
            
            PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { [weak self] verificationID, error in
                if let error = error {
                    self?.showAlert(message: error.localizedDescription)
                    return
                }
                
                UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
                self?.showAlert(message: "OTP has been resent successfully!")
            }
        }
      
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
