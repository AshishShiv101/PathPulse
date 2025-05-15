import UIKit
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import Firebase
import AuthenticationServices
import CryptoKit

class LoginPage: UIViewController {
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
    
    private let phoneTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter Phone Number"
        textField.keyboardType = .phonePad
        textField.backgroundColor = UIColor(white: 1.0, alpha: 0.9)
        textField.layer.cornerRadius = 12
        textField.textColor = .black
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.layer.borderWidth = 1
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
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
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        button.backgroundColor = UIColor(hex: "40CBD8")
        button.layer.cornerRadius = 12
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.addTarget(self, action: #selector(handleContinueButton), for: .touchUpInside)
        return button
    }()
    
    private let googleSignInButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .white
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
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
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
        
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        
        return button
    }()
    
    private let appleSignInButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .white
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
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
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
        
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        
        return button
    }()
    
    private let skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Skip", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        button.backgroundColor = UIColor(white: 0.3, alpha: 1.0) // Gray secondary button
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(handleSkipButton), for: .touchUpInside)
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
        view.addSubview(taglineLabel)
        view.addSubview(cardView)
        
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
        
        [titleLabel, subtitleLabel, phoneTextField, continueButton, googleSignInButton, appleSignInButton, skipButton].forEach {
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
            
            cardView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.50),
            cardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            
            phoneTextField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            phoneTextField.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            phoneTextField.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.85),
            phoneTextField.heightAnchor.constraint(equalToConstant: 44),
            
            continueButton.topAnchor.constraint(equalTo: phoneTextField.bottomAnchor, constant: 20),
            continueButton.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            continueButton.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.85),
            continueButton.heightAnchor.constraint(equalToConstant: 44),
            
            googleSignInButton.topAnchor.constraint(equalTo: continueButton.bottomAnchor, constant: 10),
            googleSignInButton.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            googleSignInButton.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.85),
            googleSignInButton.heightAnchor.constraint(equalToConstant: 44),
            
            appleSignInButton.topAnchor.constraint(equalTo: googleSignInButton.bottomAnchor, constant: 10),
            appleSignInButton.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            appleSignInButton.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.85),
            appleSignInButton.heightAnchor.constraint(equalToConstant: 44),
            
            skipButton.topAnchor.constraint(equalTo: appleSignInButton.bottomAnchor, constant: 10),
            skipButton.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            skipButton.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.85),
            skipButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        googleSignInButton.layer.cornerRadius = 12
        googleSignInButton.addTarget(self, action: #selector(handleGoogleSignIn), for: .touchUpInside)
        
        appleSignInButton.layer.cornerRadius = 12
        appleSignInButton.addTarget(self, action: #selector(handleAppleSignIn), for: .touchUpInside)
    }
    
    @objc private func handleContinueButton() {
        guard let phoneNumber = phoneTextField.text, !phoneNumber.isEmpty else {
            showAlert(message: "Please enter a phone number.")
            return
        }
        
        let fullPhoneNumber = "+91\(phoneNumber)"
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
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
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
    
    @objc private func handleSkipButton() {
        presentTabBarController()
    }
    
    private func presentTabBarController() {
        let tabBarController = CustomTabBarController()
        tabBarController.modalPresentationStyle = .fullScreen
        present(tabBarController, animated: true, completion: nil)
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
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        if #available(iOS 13.0, *) {
            alert.overrideUserInterfaceStyle = .light
        }
        present(alert, animated: true)
    }
}

class CustomTabBarController: UITabBarController, UITabBarControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        setupTabBar()
    }
    
    private func setupTabBar() {
        let mapPage = MapPage()
        mapPage.tabBarItem = UITabBarItem(title: "Map", image: UIImage(systemName: "map.fill"), tag: 0)
        
        let guidePage = GuidePage()
        guidePage.tabBarItem = UITabBarItem(title: "Guide", image: UIImage(systemName: "bookmark.fill"), tag: 1)
        let guideNavigationController = UINavigationController(rootViewController: guidePage)
        
        let accountPage = AccountPage()
        accountPage.tabBarItem = UITabBarItem(title: "Account", image: UIImage(systemName: "person.crop.circle"), tag: 2)
        let accountNavigationController = UINavigationController(rootViewController: accountPage)
        
        viewControllers = [mapPage, guideNavigationController, accountNavigationController]
        
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
            
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        } else {
            tabBar.barTintColor = UIColor(hex: "#151515")
            tabBar.tintColor = UIColor(hex: "#40cbd8")
            tabBar.unselectedItemTintColor = .white
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        guard let navController = viewController as? UINavigationController,
              let index = viewControllers?.firstIndex(of: navController),
              index == 2 else {
            return true
        }
        
        if Auth.auth().currentUser == nil {
            showLoginAlert(from: navController.topViewController)
            return false
        }
        return true
    }
    
    private func showLoginAlert(from sourceVC: UIViewController?) {
        let alert = UIAlertController(
            title: "Login Required",
            message: "Please login first to access the emergency contact feature.",
            preferredStyle: .alert
        )
        
        let titleAttributes = [NSAttributedString.Key.foregroundColor: UIColor(hex: "#40CBD8"),
                              NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18)]
        let messageAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white,
                                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15)]
        
        let attributedTitle = NSAttributedString(string: "Login Required", attributes: titleAttributes)
        let attributedMessage = NSAttributedString(string: alert.message ?? "", attributes: messageAttributes)
        
        alert.setValue(attributedTitle, forKey: "attributedTitle")
        alert.setValue(attributedMessage, forKey: "attributedMessage")
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurEffectView)
        
        if let bgView = alert.view.subviews.first?.subviews.first?.subviews.first {
            bgView.backgroundColor = UIColor(hex: "#333333")
            bgView.layer.cornerRadius = 12
        }
        
        let loginAction = UIAlertAction(title: "Login", style: .default) { _ in
            let loginPage = LoginPage()
            let navController = UINavigationController(rootViewController: loginPage)
            navController.modalPresentationStyle = .fullScreen
            self.present(navController, animated: true) {
                blurEffectView.removeFromSuperview()
            }
        }
        loginAction.setValue(UIColor(hex: "#40CBD8"), forKey: "titleTextColor")
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            blurEffectView.removeFromSuperview()
        }
        cancelAction.setValue(UIColor.white, forKey: "titleTextColor")
        
        alert.addAction(loginAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
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
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
                var fullName = [
                    appleIDCredential.fullName?.givenName,
                    appleIDCredential.fullName?.familyName
                ].compactMap { $0 }.joined(separator: " ")
                let email = Auth.auth().currentUser?.email ?? ""
                if fullName.isEmpty {
                    fullName = UserDefaults.standard.string(forKey: "appleUserFullName") ?? ""
                } else {
                    UserDefaults.standard.set(fullName, forKey: "appleUserFullName")
                }
                guard let uid = Auth.auth().currentUser?.uid else {
                    self.showAlert(message: "Failed to get user ID.")
                    return
                }
                let db = Firestore.firestore()
                db.collection("users").document(uid).setData([
                    "name": fullName,
                    "provider": "apple",
                    "email": Auth.auth().currentUser?.email ?? ""
                ], merge: true) { error in
                    if let error = error {
                        print("Error writing user data: \(error.localizedDescription)")
                    } else {
                        print("User name saved to Firestore")
                    }
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
