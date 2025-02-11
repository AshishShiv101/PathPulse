import UIKit
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import Firebase

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
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Pathpulse")
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
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
        textField.placeholder = "Enter Phone Number (India)"
        textField.keyboardType = .phonePad
        textField.backgroundColor = UIColor(white: 1.0, alpha: 0.9)
        textField.layer.cornerRadius = 12
        textField.textColor = .black
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.layer.borderWidth = 1
        textField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 50))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        return textField
    }()

    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send OTP", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.backgroundColor = UIColor(hex: "#40CBD8")
        button.layer.cornerRadius = 12
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.addTarget(self, action: #selector(handleContinueButton), for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }()

    private let googleSignInButton: UIButton = {
        let button = UIButton(type: .system)
        let googleLogo = UIImage(named: "Google")?.withRenderingMode(.alwaysOriginal)
        button.setImage(googleLogo, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .center
        button.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.backgroundColor = .white
        button.layer.cornerRadius = 25
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
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

        // Add tagline label to the main view (just below roadImageView)
        view.addSubview(taglineLabel)

        [titleLabel, subtitleLabel, phoneTextField, continueButton, googleSignInButton].forEach {
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

            phoneTextField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 30),
            phoneTextField.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            phoneTextField.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),

            continueButton.topAnchor.constraint(equalTo: phoneTextField.bottomAnchor, constant: 30),
            continueButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            continueButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),

            googleSignInButton.topAnchor.constraint(equalTo: continueButton.bottomAnchor, constant: 30),
            googleSignInButton.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            googleSignInButton.widthAnchor.constraint(equalToConstant: 200),
            googleSignInButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        googleSignInButton.addTarget(self, action: #selector(handleGoogleSignIn), for: .touchUpInside)
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
            
            // Store the phone number and verification ID for the OTP page
            UserDefaults.standard.set(fullPhoneNumber, forKey: "authPhoneNumber")
            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            
            // Navigate to OTP Page
            let otpVC = OTPPage()
            self.navigationController?.pushViewController(otpVC, animated: true)
        }
    }
    
    @objc private func handleGoogleSignIn() {
        // Ensure FirebaseApp is initialized
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            showAlert(message: "Client ID not found. Check Firebase configuration.")
            return
        }

        // Set up Google Sign-In Configuration
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        // Present Google Sign-In
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { result, error in
            if let error = error {
                self.showAlert(message: "Google Sign-In failed: \(error.localizedDescription)")
                return
            }

            // Extract the user and ID token
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                self.showAlert(message: "Failed to get user data.")
                return
            }

            // Create Firebase credential
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)

            // Authenticate with Firebase
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    self.showAlert(message: "Firebase sign-in failed: \(error.localizedDescription)")
                    return
                }

                let mapPage = MapPage() // Replace with your target ViewController
                self.navigationController?.pushViewController(mapPage, animated: true)
            }
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
