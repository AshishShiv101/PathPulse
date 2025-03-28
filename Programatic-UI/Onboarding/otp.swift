import UIKit
import FirebaseAuth

class OTPPage: UIViewController, UITextFieldDelegate {
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
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .gray
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let otpTextField: UITextField = {
        let textField = UITextField()
        textField.backgroundColor = UIColor(white: 1.0, alpha: 0.9)
        textField.layer.cornerRadius = 12
        textField.textColor = .black
        textField.textAlignment = .center
        textField.keyboardType = .numberPad
        textField.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.layer.borderWidth = 1
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        // Set placeholder text color explicitly
        textField.attributedPlaceholder = NSAttributedString(
            string: "Enter 6-digit OTP",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray] // Set placeholder color to gray
        )
        
        return textField
    }()
    private let verifyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Verify", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.backgroundColor = UIColor(hex: "#40CBD8")
        button.layer.cornerRadius = 12
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleVerifyButton), for: .touchUpInside)
        return button
    }()
    
    private let resendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Resend OTP", for: .normal)
        button.setTitleColor(UIColor(hex: "#40CBD8"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.backgroundColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleResendOTP), for: .touchUpInside)
        return button
    }()
    
    private let changeNumberButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Change Number", for: .normal)
        button.setTitleColor(.gray, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.backgroundColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleChangeNumber), for: .touchUpInside)
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
    
    private var resendTimer: Timer?
    private let resendCooldown = 60
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGradientBackground()
        navigationItem.hidesBackButton = true
        updateSubtitle()
        startResendCooldown()
        
        otpTextField.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
                        view.addGestureRecognizer(tap)
                
            }
            
            @objc private func dismissKeyboard() {
                    view.endEditing(true)
                }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resendTimer?.invalidate()
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
        
        logoStackContainer.addArrangedSubview(logoStack)
        logoStackContainer.addArrangedSubview(roadImageView)
        logoStackContainer.addArrangedSubview(taglineLabel)
        logoStackContainer.setCustomSpacing(-25, after: logoStack)
        logoStackContainer.setCustomSpacing(8, after: roadImageView)
        
        view.addSubview(logoStackContainer)
        view.addSubview(cardView)
        
        buttonStackView.addArrangedSubview(resendButton)
        buttonStackView.addArrangedSubview(changeNumberButton)
        
        [titleLabel, subtitleLabel, otpTextField, verifyButton, buttonStackView].forEach {
            cardView.addSubview($0)
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
            
            otpTextField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 30),
            otpTextField.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            otpTextField.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            otpTextField.heightAnchor.constraint(equalToConstant: 50),
            
            verifyButton.topAnchor.constraint(equalTo: otpTextField.bottomAnchor, constant: 30),
            verifyButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            verifyButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            
            buttonStackView.topAnchor.constraint(equalTo: verifyButton.bottomAnchor, constant: 24),
            buttonStackView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
        ])
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        // Allow only 6 characters
        if updatedText.count > 6 {
            return false
        }
        
        // Only allow numbers
        let isValidInput = string.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
        if !isValidInput {
            return false
        }
        
        // Automatically verify when 6 digits are entered
        if updatedText.count == 6 {
            textField.text = updatedText
            handleVerifyButton() // Trigger verification
            return false // Prevent further input after 6 digits
        }
        
        return true
    }
    
    @objc private func handleVerifyButton() {
        guard let otp = otpTextField.text, !otp.isEmpty else {
            showAlert(message: "Please enter the OTP.")
            return
        }
        
        guard otp.count == 6 else {
            showAlert(message: "Please enter a 6-digit OTP.")
            return
        }
        
        guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") else {
            showAlert(message: "Verification ID not found. Please try again.")
            navigationController?.popViewController(animated: true)
            return
        }
        
        verifyButton.isEnabled = false
        verifyButton.setTitle("Verifying...", for: .normal)
        
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: otp)
        
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            guard let self = self else { return }
            self.verifyButton.isEnabled = true
            self.verifyButton.setTitle("Verify", for: .normal)
            
            if let error = error {
                self.showAlert(message: "Verification failed: \(error.localizedDescription)")
                return
            }
            
            UserDefaults.standard.removeObject(forKey: "authVerificationID")
            UserDefaults.standard.removeObject(forKey: "phoneNumber")
            
            self.presentTabBarController()
        }
    }
    
    @objc private func handleResendOTP() {
        guard let phoneNumber = UserDefaults.standard.string(forKey: "phoneNumber") else {
            showAlert(message: "Phone number not found. Please enter it again.")
            navigationController?.popViewController(animated: true)
            return
        }
        
        resendButton.isEnabled = false
        resendButton.setTitle("Sending...", for: .normal)
        
        otpTextField.text = ""
        otpTextField.becomeFirstResponder()
        
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { [weak self] verificationID, error in
            guard let self = self else { return }
            
            if let error = error {
                self.showAlert(message: "Failed to resend OTP: \(error.localizedDescription)")
                self.resendButton.isEnabled = true
                self.resendButton.setTitle("Resend OTP", for: .normal)
                return
            }
            
            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            self.startResendCooldown()
            self.showSuccessAlert(message: "OTP has been resent to your device!")
        }
    }
    
    @objc private func handleChangeNumber() {
        UserDefaults.standard.removeObject(forKey: "authVerificationID")
        UserDefaults.standard.removeObject(forKey: "phoneNumber")
        navigationController?.popViewController(animated: true)
    }
    
    private func startResendCooldown() {
        var timeRemaining = resendCooldown
        resendButton.setTitle("Resend OTP (\(timeRemaining)s)", for: .normal)
        resendButton.isEnabled = false
        
        resendTimer?.invalidate()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
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
    }
    
    private func updateSubtitle() {
        if let phoneNumber = UserDefaults.standard.string(forKey: "phoneNumber") {
            subtitleLabel.text = "Enter the OTP sent to \(phoneNumber)"
        } else {
            subtitleLabel.text = "Please enter the verification code sent to your phone"
        }
    }
    
    private func presentTabBarController() {
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
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(hex: "#40cbd8")]
            appearance.stackedLayoutAppearance.normal.iconColor = .white
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
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
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showSuccessAlert(message: String) {
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    

}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
