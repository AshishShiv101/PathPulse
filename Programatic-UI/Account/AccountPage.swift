import UIKit
import FirebaseFirestore
import FirebaseAuth

class AccountPage: UIViewController {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let infoCardView = UIView()
    private let buttonsCardView = UIView()
    private let nameLabel = UILabel()
    private let phoneLabel = UILabel()
    private let privacyButton = UIButton()
    private let editContactsButton = UIButton()
    private let logoutButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#222222")
        setupScrollView()
        setupInfoCard()
        setupButtonsCard()
        fetchUserData()
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
     
    private func setupInfoCard() {
        infoCardView.backgroundColor = UIColor(hex: "#333333")
        infoCardView.layer.cornerRadius = 15
        infoCardView.layer.shadowColor = UIColor.black.cgColor
        infoCardView.layer.shadowOpacity = 0.3
        infoCardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        infoCardView.layer.shadowRadius = 6
        infoCardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(infoCardView)
        
        nameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        nameLabel.textColor = UIColor(hex: "#40CBD8")
        
        phoneLabel.font = UIFont.systemFont(ofSize: 16)
        phoneLabel.textColor = UIColor.lightGray
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        phoneLabel.translatesAutoresizingMaskIntoConstraints = false
        infoCardView.addSubview(nameLabel)
        infoCardView.addSubview(phoneLabel)
        
        let arrowImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrowImageView.tintColor = .white
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        infoCardView.addSubview(arrowImageView)

        NSLayoutConstraint.activate([
            infoCardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 60),
            infoCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            infoCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            infoCardView.heightAnchor.constraint(equalToConstant: 100),
            
            nameLabel.topAnchor.constraint(equalTo: infoCardView.topAnchor, constant: 20),
            nameLabel.leadingAnchor.constraint(equalTo: infoCardView.leadingAnchor, constant: 16),
            
            phoneLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 20),
            phoneLabel.leadingAnchor.constraint(equalTo: infoCardView.leadingAnchor, constant: 16),
            
            arrowImageView.centerYAnchor.constraint(equalTo: infoCardView.centerYAnchor),
            arrowImageView.trailingAnchor.constraint(equalTo: infoCardView.trailingAnchor, constant: -16),
        ])
    }
    
    private func setupButtonsCard() {
        buttonsCardView.backgroundColor = UIColor(hex: "#333333")
        buttonsCardView.layer.cornerRadius = 15
        buttonsCardView.layer.shadowColor = UIColor.black.cgColor
        buttonsCardView.layer.shadowOpacity = 0.3
        buttonsCardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        buttonsCardView.layer.shadowRadius = 6
        buttonsCardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(buttonsCardView)
        configureButton(privacyButton, title: "Privacy Settings", systemImageName: "lock.fill")
        configureButton(editContactsButton, title: "Emergency Contacts", systemImageName: "person.2.fill")
        configureButton(logoutButton, title: "Logout", systemImageName: "arrowshape.turn.up.left.fill")
        
        privacyButton.addTarget(self, action: #selector(privacyButtonTapped), for: .touchUpInside)
        editContactsButton.addTarget(self, action: #selector(editContactsButtonTapped), for: .touchUpInside)
        logoutButton.addTarget(self, action: #selector(logoutButtonTapped), for: .touchUpInside)
               
        let buttonStackView = UIStackView(arrangedSubviews: [privacyButton, editContactsButton, logoutButton])
        buttonStackView.axis = .vertical
        buttonStackView.spacing = 20
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonsCardView.addSubview(buttonStackView)
        
        NSLayoutConstraint.activate([
            buttonsCardView.topAnchor.constraint(equalTo: infoCardView.bottomAnchor, constant: 40),
            buttonsCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            buttonsCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            buttonsCardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            buttonStackView.topAnchor.constraint(equalTo: buttonsCardView.topAnchor, constant: 20),
            buttonStackView.leadingAnchor.constraint(equalTo: buttonsCardView.leadingAnchor, constant: 16),
            buttonStackView.trailingAnchor.constraint(equalTo: buttonsCardView.trailingAnchor, constant: -16),
            buttonStackView.bottomAnchor.constraint(equalTo: buttonsCardView.bottomAnchor, constant: -20)
        ])
    }
    
    private func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { [weak self] (document, error) in
            guard let self = self, let document = document, document.exists, error == nil else {
                print("Error fetching user data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let data = document.data() {
                self.nameLabel.text = data["name"] as? String ?? "Name not available"
                self.phoneLabel.text = "Phone: \(data["phone"] as? String ?? "Phone not available")"
            }
        }
    }
    
    private func configureButton(_ button: UIButton, title: String, systemImageName: String) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.setImage(UIImage(systemName: systemImageName), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor(hex: "#818589").withAlphaComponent(0.8)
        button.contentHorizontalAlignment = .left
        button.layer.cornerRadius = 12
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 4
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        var config = UIButton.Configuration.plain()
        config.imagePadding = 8
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0)
        button.configuration = config
        let arrowImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrowImageView.tintColor = .white
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(arrowImageView)
        
        NSLayoutConstraint.activate([
            arrowImageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            arrowImageView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16)
        ])
    }
    @objc func privacyButtonTapped() {
        if let appSettingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(appSettingsURL, options: [:], completionHandler: nil)
        }
    }
    
    @objc func editContactsButtonTapped() {
        let editContactVC = EditContactViewController()
        navigationController?.pushViewController(editContactVC, animated: true)
    }
    
    @objc func logoutButtonTapped() {
        let alertController = UIAlertController(
            title: "Logout",
            message: "Are you sure you want to log out?",
            preferredStyle: .alert
        )
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        let logoutAction = UIAlertAction(title: "Logout", style: .destructive) { _ in
            self.performLogout()
        }
        alertController.addAction(logoutAction)

        present(alertController, animated: true, completion: nil)
    }
    
    private func performLogout() {
        do {
            try Auth.auth().signOut()
            
            // Create an instance of LoginViewController
            let loginVC = LoginPage()
            loginVC.modalPresentationStyle = .fullScreen
            
            // Replace the root view controller
            if let window = UIApplication.shared.windows.first {
                window.rootViewController = loginVC
                UIView.transition(
                    with: window,
                    duration: 0.5,
                    options: .transitionCrossDissolve,
                    animations: nil,
                    completion: nil
                )
            }
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
