import UIKit
class LoginPage: UIViewController {
    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter Username"
        textField.backgroundColor = UIColor(white: 1.0, alpha: 0.7)
        textField.layer.cornerRadius = 12
        textField.textColor = .black
        textField.layer.borderColor = UIColor.gray.cgColor
        textField.layer.borderWidth = 1
        textField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 50))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        return textField
    }()

    private let usernameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Phone number"
        textField.backgroundColor = UIColor(white: 1.0, alpha: 0.7)
        textField.layer.cornerRadius = 12
        textField.textColor = .black
        textField.layer.borderColor = UIColor.gray.cgColor
        textField.layer.borderWidth = 1
        textField.heightAnchor.constraint(equalToConstant: 50).isActive = true

        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 50))
        textField.leftView = paddingView
        textField.leftViewMode = .always

        return textField
    }()

    
    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Continue", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold) 
        button.backgroundColor = UIColor(hex: "#40CBD8")
        button.layer.cornerRadius = 12
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 3)
        button.layer.shadowOpacity = 0.3
        button.addTarget(self, action: #selector(handleContinueButton), for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }()
    private let googleButton: UIButton = createSocialButton(imageName: "Google", backgroundColor: .white)
    private let appleButton: UIButton = createSocialButton(imageName: "Apple", backgroundColor: .white)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#222222")
        
        let appLogo = AppLogoView()
        appLogo.contentMode = .scaleAspectFit
        
        let titleLabel = UILabel()
        titleLabel.text = "Log in or Sign Up"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 28)
        titleLabel.textColor = UIColor(hex: "#F2F1F1")
        titleLabel.textAlignment = .center
        
        let connectLabel = UILabel()
        connectLabel.text = "Connect with"
        connectLabel.font = UIFont.boldSystemFont(ofSize: 14)
        connectLabel.textColor = UIColor(hex: "#F2F1F1")
        
        let separatorContainer = createSeparatorWithOrLabel()
        
        let buttonStack = UIStackView(arrangedSubviews: [googleButton, appleButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 24
        
        [appLogo, titleLabel, emailTextField, usernameTextField, continueButton, separatorContainer, connectLabel, buttonStack].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
               appLogo.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
               appLogo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
               appLogo.widthAnchor.constraint(equalToConstant: 120),
               appLogo.heightAnchor.constraint(equalToConstant: 120),
               
               titleLabel.topAnchor.constraint(equalTo: appLogo.bottomAnchor, constant: 40),
               titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
               
               emailTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
               emailTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
               emailTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
               
               usernameTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 16),
               usernameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
               usernameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
               
               continueButton.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 24),
               continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
               continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
               
               separatorContainer.topAnchor.constraint(equalTo: continueButton.bottomAnchor, constant: 32),
               separatorContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
               separatorContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
               separatorContainer.heightAnchor.constraint(equalToConstant: 30),
               
               connectLabel.topAnchor.constraint(equalTo: separatorContainer.bottomAnchor, constant: 20),
               connectLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
               
               buttonStack.topAnchor.constraint(equalTo: connectLabel.bottomAnchor, constant: 20),
               buttonStack.centerXAnchor.constraint(equalTo: view.centerXAnchor)
           ])
       }
    
    private func createSeparatorWithOrLabel() -> UIView {
        let separatorContainer = UIView()
        separatorContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let separatorLine1 = createSeparatorLine()
        let separatorLine2 = createSeparatorLine()
        
        let orLabel = UILabel()
        orLabel.text = "Or"
        orLabel.font = UIFont.boldSystemFont(ofSize: 14)
        orLabel.textColor = UIColor(hex: "#F2F1F1")
        orLabel.backgroundColor = view.backgroundColor
        orLabel.textAlignment = .center
        orLabel.translatesAutoresizingMaskIntoConstraints = false
        
        separatorContainer.addSubview(separatorLine1)
        separatorContainer.addSubview(orLabel)
        separatorContainer.addSubview(separatorLine2)
        
        NSLayoutConstraint.activate([
            separatorLine1.leadingAnchor.constraint(equalTo: separatorContainer.leadingAnchor),
            separatorLine1.trailingAnchor.constraint(equalTo: orLabel.leadingAnchor, constant: -8),
            separatorLine1.centerYAnchor.constraint(equalTo: separatorContainer.centerYAnchor),
            separatorLine1.heightAnchor.constraint(equalToConstant: 1),
            
            orLabel.centerYAnchor.constraint(equalTo: separatorContainer.centerYAnchor),
            orLabel.centerXAnchor.constraint(equalTo: separatorContainer.centerXAnchor),
            
            separatorLine2.leadingAnchor.constraint(equalTo: orLabel.trailingAnchor, constant: 8),
            separatorLine2.trailingAnchor.constraint(equalTo: separatorContainer.trailingAnchor),
            separatorLine2.centerYAnchor.constraint(equalTo: separatorContainer.centerYAnchor),
            separatorLine2.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        return separatorContainer
    }
    
    private static func createSocialButton(imageName: String, backgroundColor: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = backgroundColor
        button.layer.cornerRadius = 12
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.3
        
        let imageView = UIImageView(image: UIImage(named: imageName))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageView.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        button.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width / 4).isActive = true
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }
    
    private func createSeparatorLine() -> UIView {
        let line = UIView()
        line.backgroundColor = UIColor(hex: "#F2F1F1").withAlphaComponent(0.5)
        line.translatesAutoresizingMaskIntoConstraints = false
        return line
    }
    @objc private func handleContinueButton() {
        let authenticateVC = OTPPage() // Replace with your initialization logic if needed

//         Navigate to Authenticate page
        self.navigationController?.pushViewController(authenticateVC, animated: true)
    }
}
