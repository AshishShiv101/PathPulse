import UIKit

class LoginPage: UIViewController {
    
    // UI Elements
    private let usernameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter ID or Phone number"
        textField.backgroundColor = UIColor(white: 1.0, alpha: 0.7)
        textField.layer.cornerRadius = 10
        textField.textColor = .black
        textField.setLeftPaddingPoints(10)
        textField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return textField
    }()
    
    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Continue", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(hex: "40CBD8")
        button.layer.cornerRadius = 10
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 3)
        button.layer.shadowOpacity = 0.3
        button.addTarget(self, action: #selector(handleContinueButton), for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }()
    
    private let googleButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.layer.cornerRadius = 10
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.3

        let googleImageView = UIImageView(image: UIImage(named: "Google"))
        googleImageView.contentMode = .scaleAspectFit
        googleImageView.tintColor = .black
        googleImageView.translatesAutoresizingMaskIntoConstraints = false

        button.addSubview(googleImageView)
        NSLayoutConstraint.activate([
            googleImageView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            googleImageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            googleImageView.widthAnchor.constraint(equalToConstant: 24),
            googleImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // Set width to 1/4 of the screen width
        button.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width / 4).isActive = true
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.addTarget(self, action: #selector(googleButtonTapped), for: .touchUpInside)
        return button
    }()

    private let appleButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.layer.cornerRadius = 10
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.3

        let appleImageView = UIImageView(image: UIImage(named: "Apple"))
        appleImageView.contentMode = .scaleAspectFit
        appleImageView.tintColor = .black
        appleImageView.translatesAutoresizingMaskIntoConstraints = false

        button.addSubview(appleImageView)
        NSLayoutConstraint.activate([
            appleImageView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            appleImageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            appleImageView.widthAnchor.constraint(equalToConstant: 24),
            appleImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // Set width to 1/4 of the screen width
        button.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width / 4).isActive = true
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.addTarget(self, action: #selector(appleButtonTapped), for: .touchUpInside)
        return button
    }()


    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#222222")
        
        let appLogo = AppLogoView()
        appLogo.contentMode = .scaleAspectFit
        
        let titleLabel = UILabel()
        titleLabel.text = "Log in or Sign Up"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textColor = UIColor(hex: "F2F1F1")
        titleLabel.textAlignment = .center
        
        let orLabel = UILabel()
        orLabel.text = "Or"
        orLabel.font = UIFont.boldSystemFont(ofSize: 14)
        orLabel.textColor = UIColor(hex: "F2F1F1")
        
        let connectLabel = UILabel()
        connectLabel.text = "Connect with"
        connectLabel.font = UIFont.boldSystemFont(ofSize: 14)
        connectLabel.textColor = UIColor(hex: "F2F1F1")
        
        let separatorLine1 = UIView()
        separatorLine1.backgroundColor = UIColor(hex: "F2F1F1")
        
        let separatorLine2 = UIView()
        separatorLine2.backgroundColor = UIColor(hex: "F2F1F1")
        
        let buttonStack = UIStackView(arrangedSubviews: [googleButton, appleButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 50
        
        let separatorStack = UIStackView(arrangedSubviews: [separatorLine1, separatorLine2])
        separatorStack.axis = .horizontal
        separatorStack.spacing = 50
        separatorStack.distribution = .fillEqually
        
        [appLogo, titleLabel, usernameTextField, continueButton, orLabel, separatorStack, connectLabel, buttonStack].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            appLogo.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            appLogo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            appLogo.widthAnchor.constraint(equalToConstant: 100),
            appLogo.heightAnchor.constraint(equalToConstant: 100),
            
            titleLabel.topAnchor.constraint(equalTo: appLogo.bottomAnchor, constant: 30),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            usernameTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            usernameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            usernameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            continueButton.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 20),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            orLabel.topAnchor.constraint(equalTo: continueButton.bottomAnchor, constant: 20),
            orLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            separatorStack.topAnchor.constraint(equalTo: orLabel.bottomAnchor, constant: 10),
            separatorStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            separatorStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            separatorStack.heightAnchor.constraint(equalToConstant: 1),
            
            connectLabel.topAnchor.constraint(equalTo: separatorStack.bottomAnchor, constant: 10),
            connectLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            buttonStack.topAnchor.constraint(equalTo: connectLabel.bottomAnchor, constant: 10),
            buttonStack.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc private func handleContinueButton() {
        // Initialize MapPage
        let mapPage = MapPage()
        mapPage.tabBarItem = UITabBarItem(title: "Map", image: UIImage(systemName: "map.fill"), tag: 0)
        
        // Initialize GuidePage and embed it in a UINavigationController
        let guidePage = GuidePage()
        guidePage.tabBarItem = UITabBarItem(title: "Guide", image: UIImage(systemName: "bookmark.fill"), tag: 1)
        let guideNavigationController = UINavigationController(rootViewController: guidePage)
        
        // Initialize AccountPage
        let accountPage = AccountPage()
        accountPage.tabBarItem = UITabBarItem(title: "Account", image: UIImage(systemName: "person.crop.circle"), tag: 2)
        
        // Initialize UITabBarController
        let tabBarController = UITabBarController()
        
        // Set up view controllers
        tabBarController.viewControllers = [mapPage, guideNavigationController, accountPage]
        
        // Customize tab bar appearance
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(hex: "#151515")
            
            // Set the color for unselected and selected items
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(hex: "#40cbd8")
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(hex: "#40cbd8")]
            appearance.stackedLayoutAppearance.normal.iconColor = .white
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            
            tabBarController.tabBar.standardAppearance = appearance
            tabBarController.tabBar.scrollEdgeAppearance = appearance
        } else {
            // For iOS 14 and below
            tabBarController.tabBar.barTintColor = UIColor(hex: "#151515")
            tabBarController.tabBar.tintColor = UIColor(hex: "#40cbd8")
            tabBarController.tabBar.unselectedItemTintColor = .white
        }
        
        tabBarController.modalPresentationStyle = .fullScreen
        present(tabBarController, animated: true, completion: nil)
    }


    @objc private func googleButtonTapped() {
        // Handle Google Login
    }
    
    @objc private func appleButtonTapped() {
        // Handle Apple Login
    }
    
}

extension UITextField {
    func setLeftPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}
