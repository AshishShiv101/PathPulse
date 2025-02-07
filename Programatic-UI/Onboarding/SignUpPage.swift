import UIKit
import FirebaseAuth
import FirebaseFirestore

class SignUpPage: UIViewController {

    private let nameTextField = SignUpPage.createStyledTextField(placeholder: "Enter Name")
    private let phoneTextField = SignUpPage.createStyledTextField(placeholder: "Enter Phone Number (India)")
    private let emailTextField = SignUpPage.createStyledTextField(placeholder: "Enter Email", autocapitalization: .none)
    private let passwordTextField = SignUpPage.createStyledSecureTextField(placeholder: "Enter Password")
    private let confirmPasswordTextField = SignUpPage.createStyledSecureTextField(placeholder: "Confirm Password")

    private let signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.backgroundColor = UIColor(hex: "#40CBD8")
        button.layer.cornerRadius = 12
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 3)
        button.layer.shadowOpacity = 0.3
        button.addTarget(self, action: #selector(handleSignUpButton), for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }()

    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Already have an account? Log In", for: .normal)
        button.setTitleColor(UIColor(hex: "#40CBD8"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        button.addTarget(self, action: #selector(handleLoginButton), for: .touchUpInside)
        return button
    }()

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.textColor = .red
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private let appLogoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "AppLogo")
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 60
        imageView.clipsToBounds = true
        return imageView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#222222")
        navigationItem.hidesBackButton = true
        setupUI()
    }

    private func setupUI() {
        let appLogo = AppLogoView() // Use the reusable AppLogoView
        
        let titleLabel = UILabel()
        titleLabel.text = "Sign Up"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 28)
        titleLabel.textColor = UIColor(hex: "#F2F1F1")
        titleLabel.textAlignment = .center

        let stackView = UIStackView(arrangedSubviews: [
            appLogo, // Add the app logo to the stack
            titleLabel,
            nameTextField,
            phoneTextField,
            emailTextField,
            passwordTextField,
            confirmPasswordTextField,
            signUpButton,
            loginButton, // Add login button below Sign Up button
            errorLabel
        ])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.distribution = .fill

        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            appLogo.heightAnchor.constraint(equalToConstant: 120), // Ensure logo height consistency
            appLogo.widthAnchor.constraint(equalToConstant: 120)
        ])
    }

    @objc private func handleSignUpButton() {
        guard let name = nameTextField.text, !name.isEmpty else {
            showError(message: "Name cannot be empty.")
            return
        }
        guard let phone = phoneTextField.text, isValidPhone(phone) else {
            showError(message: "Invalid phone number. Please enter a valid 10-digit number.")
            return
        }
        guard let email = emailTextField.text, isValidEmail(email) else {
            showError(message: "Invalid email address.")
            return
        }
        guard let password = passwordTextField.text, isValidPassword(password) else {
            showError(message: "Password must be at least 6 characters long.")
            return
        }
        guard let confirmPassword = confirmPasswordTextField.text, confirmPassword == password else {
            showError(message: "Passwords do not match.")
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                // Improved error handling based on Firebase error codes
                var errorMessage = "Sign Up Failed"
                if let errorCode = AuthErrorCode(rawValue: error._code) {
                    switch errorCode {
                    case .emailAlreadyInUse:
                        errorMessage = "This email is already registered."
                    case .invalidEmail:
                        errorMessage = "Invalid email format."
                    case .weakPassword:
                        errorMessage = "Password is too weak. Use at least 6 characters."
                    default:
                        errorMessage = error.localizedDescription
                    }
                }
                self.showError(message: errorMessage)
                return
            }

            // Get the user’s UID from Firebase Authentication
            guard let user = result?.user else {
                self.showError(message: "Failed to retrieve user information.")
                return
            }

            // Create user data to store in Firestore
            let userData: [String: Any] = [
                "name": name,
                "phone": phone,
                "email": email,
                "uid": user.uid,
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            // Get a reference to Firestore
            let db = Firestore.firestore()

            // Add user data to the 'users' collection using the UID as the document ID
            db.collection("users").document(user.uid).setData(userData) { error in
                if let error = error {
                    self.showError(message: "Failed to save user data: \(error.localizedDescription)")
                } else {
                    let alert = UIAlertController(title: "Success", message: "Sign Up Successful! Please log in.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        self.navigationController?.popViewController(animated: true)
                    })
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }

    @objc private func handleLoginButton() {
        navigationController?.popViewController(animated: true)
    }

    private func showError(message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
    }

    private static func createStyledTextField(placeholder: String, autocapitalization: UITextAutocapitalizationType = .sentences) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.backgroundColor = UIColor(white: 1.0, alpha: 0.7)
        textField.layer.cornerRadius = 12
        textField.textColor = .black
        textField.layer.borderColor = UIColor.gray.cgColor
        textField.layer.borderWidth = 1
        textField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 50))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        textField.autocapitalizationType = autocapitalization
        return textField
    }

    private static func createStyledSecureTextField(placeholder: String) -> UITextField {
        let textField = createStyledTextField(placeholder: placeholder)
        textField.isSecureTextEntry = true
        return textField
    }

    private func isValidPhone(_ phone: String) -> Bool {
        let phoneRegex = "^[6-9]\\d{9}$"
        return NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: phone)
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }

    private func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6
    }
}
