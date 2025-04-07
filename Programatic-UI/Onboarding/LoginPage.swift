import UIKit
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import Firebase
import AuthenticationServices
import CryptoKit



class LoginPage: UIViewController {
    // Country code data structure
    struct CountryCode {
        let name: String
        let code: String
    }
    
    private let countryCodes: [CountryCode] = [
        CountryCode(name: "India", code: "+91"),
        CountryCode(name: "United States", code: "+1"),
        CountryCode(name: "United Kingdom", code: "+44"),
        CountryCode(name: "Australia", code: "+61"),
        CountryCode(name: "Canada", code: "+1"),
    ]
    
    private var selectedCountryCode = "+91"
    
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
    
    private var currentNonce: String?
    
    private let roadImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "road.lanes.curved.right"))
        imageView.tintColor = UIColor(hex: "40CBD8")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
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
    
    private lazy var phoneTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter Phone Number"
        textField.keyboardType = .phonePad
        textField.backgroundColor = .white
        textField.layer.cornerRadius = 12
        textField.textColor = .black
        textField.layer.borderWidth = 0
        textField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        textField.translatesAutoresizingMaskIntoConstraints = false // Ensure constraints are used
        
        let countryButton = UIButton(type: .system)
        countryButton.setTitle(selectedCountryCode, for: .normal)
        countryButton.setTitleColor(.black, for: .normal)
        countryButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        countryButton.addTarget(self, action: #selector(showCountryPicker), for: .touchUpInside)
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 50))
        countryButton.frame = CGRect(x: 10, y: 0, width: 50, height: 50)
        paddingView.addSubview(countryButton)
        
        textField.leftView = paddingView
        textField.leftViewMode = .always
        
        textField.attributedPlaceholder = NSAttributedString(
            string: "Enter Phone Number",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray]
        )
        
        return textField
    }()
    
    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send OTP", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.backgroundColor = UIColor(hex: "#40CBD8")
        button.layer.cornerRadius = 12
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.translatesAutoresizingMaskIntoConstraints = false // Ensure constraints are used
        button.addTarget(self, action: #selector(handleContinueButton), for: .touchUpInside)
        return button
    }()
    
    private let googleSignInButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .white
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView(image: UIImage(named: "Google")?.withRenderingMode(.alwaysOriginal))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageView.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        let label = UILabel()
        label.text = "Sign in with Google"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView(arrangedSubviews: [imageView, label])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isUserInteractionEnabled = false
        
        button.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
        ])
        
        return button
    }()
    
    private let appleSignInButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .white
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView(image: UIImage(systemName: "apple.logo")?.withTintColor(.black, renderingMode: .alwaysOriginal))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageView.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        let label = UILabel()
        label.text = "Sign in with Apple"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView(arrangedSubviews: [imageView, label])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isUserInteractionEnabled = false
        
        button.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
        ])
        
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGradientBackground()
        navigationItem.hidesBackButton = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
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
        logoStackContainer.addArrangedSubview(logoStack)
        logoStackContainer.addArrangedSubview(roadImageView)
        view.addSubview(logoStackContainer)
        view.backgroundColor = UIColor(hex: "#222222")
        
        let titleLabel = UILabel()
        titleLabel.text = "Welcome to Pathpulse"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 28)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Enter your phone number to continue"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textColor = .gray
        subtitleLabel.textAlignment = .center
        
        view.addSubview(cardView)
        view.addSubview(taglineLabel)
        
        [titleLabel, subtitleLabel, phoneTextField, continueButton, googleSignInButton, appleSignInButton].forEach {
            cardView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            logoStackContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            logoStackContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            roadImageView.widthAnchor.constraint(equalToConstant: 100),
            roadImageView.heightAnchor.constraint(equalToConstant: 100),
            
            taglineLabel.topAnchor.constraint(equalTo: roadImageView.bottomAnchor, constant: 10),
            taglineLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            cardView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.55),
            cardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            
            phoneTextField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            phoneTextField.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            phoneTextField.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.85),
            phoneTextField.heightAnchor.constraint(equalToConstant: 50),
            
            continueButton.topAnchor.constraint(equalTo: phoneTextField.bottomAnchor, constant: 20),
            continueButton.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            continueButton.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.85),
            continueButton.heightAnchor.constraint(equalToConstant: 50),
            
            googleSignInButton.topAnchor.constraint(equalTo: continueButton.bottomAnchor, constant: 15),
            googleSignInButton.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            googleSignInButton.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.85),
            googleSignInButton.heightAnchor.constraint(equalToConstant: 50),
            
            appleSignInButton.topAnchor.constraint(equalTo: googleSignInButton.bottomAnchor, constant: 15),
            appleSignInButton.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            appleSignInButton.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.85),
            appleSignInButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        googleSignInButton.addTarget(self, action: #selector(handleGoogleSignIn), for: .touchUpInside)
        appleSignInButton.addTarget(self, action: #selector(handleAppleSignIn), for: .touchUpInside)
    }
    
    @objc private func showCountryPicker() {
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        
        // Style the picker
        picker.backgroundColor = UIColor(hex: "#333333")
        picker.layer.cornerRadius = 12
        picker.layer.borderWidth = 1
        picker.layer.borderColor = UIColor(hex: "40CBD8").withAlphaComponent(0.3).cgColor
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(picker)
        
        let alert = UIAlertController(title: "Select Country Code", message: nil, preferredStyle: .actionSheet)
        
        alert.view.tintColor = UIColor(hex: "40CBD8")
        if #available(iOS 13.0, *) {
            alert.overrideUserInterfaceStyle = .dark
        }
        
        alert.view.addSubview(containerView)
        
        let doneAction = UIAlertAction(title: "Done", style: .default) { _ in
            let selectedRow = picker.selectedRow(inComponent: 0)
            self.selectedCountryCode = self.countryCodes[selectedRow].code
            if let countryButton = self.phoneTextField.leftView?.subviews.first as? UIButton {
                countryButton.setTitle(self.selectedCountryCode, for: .normal)
            }
        }
        doneAction.setValue(UIColor(hex: "40CBD8"), forKey: "titleTextColor")
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        cancelAction.setValue(UIColor.gray, forKey: "titleTextColor")
        
        alert.addAction(doneAction)
        alert.addAction(cancelAction)
        
        picker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            picker.topAnchor.constraint(equalTo: containerView.topAnchor),
            picker.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            picker.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            picker.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            picker.heightAnchor.constraint(equalToConstant: 150)
        ])
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 40),
            containerView.leadingAnchor.constraint(equalTo: alert.view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: alert.view.trailingAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 150)
        ])
        
        let height = NSLayoutConstraint(
            item: alert.view!,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1,
            constant: 300
        )
        alert.view.addConstraint(height)
        
        present(alert, animated: true)
    }
    
    @objc private func handleContinueButton() {
        guard let phoneNumber = phoneTextField.text, !phoneNumber.isEmpty else {
            showAlert(message: "Please enter a phone number.")
            return
        }
        
        let fullPhoneNumber = "\(selectedCountryCode)\(phoneNumber)"
        PhoneAuthProvider.provider().verifyPhoneNumber(fullPhoneNumber, uiDelegate: nil) { verificationID, error in
            if let error = error {
                self.showAlert(message: "Failed to send OTP: \(error.localizedDescription)")
                return
            }
            
            UserDefaults.standard.set(fullPhoneNumber, forKey: "authPhoneNumber")
            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            
            let otpVC = OTPPage()
            self.navigationController?.pushViewController(otpVC, animated: true)
        }
    }
    
    @objc private func handleGoogleSignIn() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            showAlert(message: "Client ID not found. Check Firebase configuration.")
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { result, error in
            if let error = error {
                self.showAlert(message: "Google Sign-In failed: \(error.localizedDescription)")
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                self.showAlert(message: "Failed to get user data.")
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    self.showAlert(message: "Firebase sign-in failed: \(error.localizedDescription)")
                    return
                }
                
                self.presentTabBarController()
            }
        }
    }
    
    @objc private func handleAppleSignIn() {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            for random in randoms {
                if remainingLength == 0 {
                    break
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
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
            
            let selectedColor = UIColor(hex: "#40cbd8")
            let normalColor = UIColor.white
            
            appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: selectedColor]
            appearance.stackedLayoutAppearance.normal.iconColor = normalColor
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: normalColor]
            
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
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension LoginPage: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return countryCodes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        label.text = "\(countryCodes[row].name) (\(countryCodes[row].code))"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        if #available(iOS 13.0, *) {
            label.textColor = .white
        } else {
            label.textColor = .white
        }
        
        if pickerView.selectedRow(inComponent: component) == row {
            label.textColor = UIColor(hex: "40CBD8")
        }
        
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickerView.reloadAllComponents()
    }
}

extension LoginPage: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8),
                  let nonce = currentNonce else {
                showAlert(message: "Unable to fetch Apple ID token or nonce.")
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                    idToken: idTokenString,
                                                    rawNonce: nonce)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    self.showAlert(message: "Apple Sign-In failed: \(error.localizedDescription)")
                    return
                }
                self.presentTabBarController()
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        showAlert(message: "Apple Sign-In failed: \(error.localizedDescription)")
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
