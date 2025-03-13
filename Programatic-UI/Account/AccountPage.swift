import UIKit
import FirebaseFirestore
import FirebaseAuth

// MARK: - UITextField Padding Extension
extension UITextField {
    func setLeftPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}

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
    
    private let editInfoBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let editInfoContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#333333")
        view.layer.cornerRadius = 15
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let editNameTextField: UITextField = {
        let tf = UITextField()
        let placeholderText = "Enter your name"
        tf.attributedPlaceholder = NSAttributedString(string: placeholderText,
                                                      attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        tf.borderStyle = .none
        tf.backgroundColor = UIColor(hex: "#222222")
        tf.textColor = .white
        tf.layer.cornerRadius = 8
        tf.clipsToBounds = true
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let editPhoneTextField: UITextField = {
        let tf = UITextField()
        let placeholderText = "Enter your phone number"
        tf.attributedPlaceholder = NSAttributedString(string: placeholderText,
                                                      attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        tf.borderStyle = .none
        tf.backgroundColor = UIColor(hex: "#222222")
        tf.textColor = .white
        tf.layer.cornerRadius = 8
        tf.clipsToBounds = true
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.keyboardType = .phonePad
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let saveEditButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save", for: .normal)
        button.backgroundColor = UIColor(hex: "#40CBD8")
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupEditInfoView()
        fetchUserData()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#222222")
        
        // Scroll View Setup (unchanged)
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
        
        // Info Card Setup (unchanged)
        infoCardView.backgroundColor = UIColor(hex: "#333333")
        infoCardView.layer.cornerRadius = 20
        infoCardView.layer.masksToBounds = true
        infoCardView.layer.shadowColor = UIColor.black.cgColor
        infoCardView.layer.shadowOpacity = 0.2
        infoCardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        infoCardView.layer.shadowRadius = 8
        infoCardView.translatesAutoresizingMaskIntoConstraints = false
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: view.bounds.width - 32, height: 120)
        gradientLayer.colors = [UIColor(hex: "#333333").cgColor, UIColor(hex: "#2A2A2A").cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        infoCardView.layer.insertSublayer(gradientLayer, at: 0)
        
        contentView.addSubview(infoCardView)
        
        nameLabel.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        nameLabel.textColor = UIColor(hex: "#40CBD8")
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        phoneLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        phoneLabel.textColor = .lightGray
        phoneLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let editIconView = UIImageView(image: UIImage(systemName: "pencil")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 25, weight: .semibold)))
        editIconView.tintColor = UIColor(hex: "#40CBD8")
        editIconView.translatesAutoresizingMaskIntoConstraints = false
        editIconView.isUserInteractionEnabled = true
        editIconView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(editAccountInfoTapped)))
        
        infoCardView.addSubview(nameLabel)
        infoCardView.addSubview(phoneLabel)
        infoCardView.addSubview(editIconView)
        
        NSLayoutConstraint.activate([
            infoCardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            infoCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            infoCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            infoCardView.heightAnchor.constraint(equalToConstant: 120),
            
            nameLabel.topAnchor.constraint(equalTo: infoCardView.topAnchor, constant: 24),
            nameLabel.leadingAnchor.constraint(equalTo: infoCardView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: editIconView.leadingAnchor, constant: -10),
            
            phoneLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 12),
            phoneLabel.leadingAnchor.constraint(equalTo: infoCardView.leadingAnchor, constant: 20),
            
            editIconView.centerYAnchor.constraint(equalTo: infoCardView.centerYAnchor),
            editIconView.trailingAnchor.constraint(equalTo: infoCardView.trailingAnchor, constant: -20),
            editIconView.widthAnchor.constraint(equalToConstant: 30),
            editIconView.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // Buttons Card Setup
        buttonsCardView.backgroundColor = UIColor(hex: "#333333")
        buttonsCardView.layer.cornerRadius = 20
        buttonsCardView.layer.shadowColor = UIColor.black.cgColor
        buttonsCardView.layer.shadowOpacity = 0.2
        buttonsCardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        buttonsCardView.layer.shadowRadius = 8
        buttonsCardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(buttonsCardView)
        
        // Configure buttons with distinct style for Emergency Contacts
        configureButton(editContactsButton, title: "Emergency Contacts", systemImageName: "person.2.fill", isHighlighted: true)
        configureButton(privacyButton, title: "Privacy Settings", systemImageName: "lock.fill", isHighlighted: false)
        configureButton(logoutButton, title: "Logout", systemImageName: "arrowshape.turn.up.left.fill", isHighlighted: false)
        
        editContactsButton.addTarget(self, action: #selector(editContactsButtonTapped), for: .touchUpInside)
        privacyButton.addTarget(self, action: #selector(privacyButtonTapped), for: .touchUpInside)
        logoutButton.addTarget(self, action: #selector(logoutButtonTapped), for: .touchUpInside)
        
        let buttonStackView = UIStackView(arrangedSubviews: [editContactsButton, privacyButton, logoutButton])
        buttonStackView.axis = .vertical
        buttonStackView.spacing = 16
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonsCardView.addSubview(buttonStackView)
        
        NSLayoutConstraint.activate([
            buttonsCardView.topAnchor.constraint(equalTo: infoCardView.bottomAnchor, constant: 30),
            buttonsCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            buttonsCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            buttonsCardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
            
            buttonStackView.topAnchor.constraint(equalTo: buttonsCardView.topAnchor, constant: 24),
            buttonStackView.leadingAnchor.constraint(equalTo: buttonsCardView.leadingAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: buttonsCardView.trailingAnchor, constant: -20),
            buttonStackView.bottomAnchor.constraint(equalTo: buttonsCardView.bottomAnchor, constant: -24)
        ])
    }
    
    private func configureButton(_ button: UIButton, title: String, systemImageName: String, isHighlighted: Bool) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.setImage(UIImage(systemName: systemImageName)?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)), for: .normal)
        button.tintColor = .white
        button.contentHorizontalAlignment = .left
        
        if isHighlighted { // Distinct style for Emergency Contacts
            button.backgroundColor = UIColor(hex: "#40CBD8").withAlphaComponent(0.9) // Brighter accent color
            button.layer.cornerRadius = 16
            button.heightAnchor.constraint(equalToConstant: 60).isActive = true // Slightly taller
            button.layer.borderWidth = 1.5
            button.layer.borderColor = UIColor(hex: "#FFFFFF").withAlphaComponent(0.3).cgColor // Subtle white border
            button.layer.shadowColor = UIColor(hex: "#40CBD8").cgColor // Match shadow to accent
            button.layer.shadowOpacity = 0.4
            button.layer.shadowOffset = CGSize(width: 0, height: 3)
            button.layer.shadowRadius = 6
        } else { // Standard style for other buttons
            button.backgroundColor = UIColor(hex: "#818589").withAlphaComponent(0.9)
            button.layer.cornerRadius = 14
            button.heightAnchor.constraint(equalToConstant: 56).isActive = true
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOpacity = 0.1
            button.layer.shadowOffset = CGSize(width: 0, height: 2)
            button.layer.shadowRadius = 4
        }
        
        var config = UIButton.Configuration.plain()
        config.imagePadding = 12
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 0)
        button.configuration = config
        
        let arrowImageView = UIImageView(image: UIImage(systemName: "chevron.right")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)))
        arrowImageView.tintColor = .white
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(arrowImageView)
        
        NSLayoutConstraint.activate([
            arrowImageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            arrowImageView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Edit Info Overlay Setup (unchanged)
    private func setupEditInfoView() {
        view.addSubview(editInfoBackgroundView)
        editInfoBackgroundView.addSubview(editInfoContainerView)
        editInfoContainerView.addSubview(editNameTextField)
        editInfoContainerView.addSubview(editPhoneTextField)
        editInfoContainerView.addSubview(saveEditButton)
        
        editInfoContainerView.layer.shadowColor = UIColor.black.cgColor
        editInfoContainerView.layer.shadowOpacity = 0.3
        editInfoContainerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        editInfoContainerView.layer.shadowRadius = 10
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        editInfoBackgroundView.addGestureRecognizer(tapGesture)
        
        NSLayoutConstraint.activate([
            editInfoBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            editInfoBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            editInfoBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            editInfoBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            editInfoContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            editInfoContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            editInfoContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
            editInfoContainerView.heightAnchor.constraint(equalToConstant: 240),
            
            editNameTextField.topAnchor.constraint(equalTo: editInfoContainerView.topAnchor, constant: 30),
            editNameTextField.leadingAnchor.constraint(equalTo: editInfoContainerView.leadingAnchor, constant: 20),
            editNameTextField.trailingAnchor.constraint(equalTo: editInfoContainerView.trailingAnchor, constant: -20),
            editNameTextField.heightAnchor.constraint(equalToConstant: 48),
            
            editPhoneTextField.topAnchor.constraint(equalTo: editNameTextField.bottomAnchor, constant: 20),
            editPhoneTextField.leadingAnchor.constraint(equalTo: editInfoContainerView.leadingAnchor, constant: 20),
            editPhoneTextField.trailingAnchor.constraint(equalTo: editInfoContainerView.trailingAnchor, constant: -20),
            editPhoneTextField.heightAnchor.constraint(equalToConstant: 48),
            
            saveEditButton.bottomAnchor.constraint(equalTo: editInfoContainerView.bottomAnchor, constant: -30),
            saveEditButton.trailingAnchor.constraint(equalTo: editInfoContainerView.trailingAnchor, constant: -20),
            saveEditButton.widthAnchor.constraint(equalToConstant: 100),
            saveEditButton.heightAnchor.constraint(equalToConstant: 48)
        ])
        
        editNameTextField.setLeftPaddingPoints(12)
        editPhoneTextField.setLeftPaddingPoints(12)
        editNameTextField.layer.borderWidth = 1
        editNameTextField.layer.borderColor = UIColor(hex: "#40CBD8").withAlphaComponent(0.2).cgColor
        editPhoneTextField.layer.borderWidth = 1
        editPhoneTextField.layer.borderColor = UIColor(hex: "#40CBD8").withAlphaComponent(0.2).cgColor
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: 100, height: 48)
        gradientLayer.colors = [UIColor(hex: "#40CBD8").cgColor, UIColor(hex: "#36A8B3").cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        saveEditButton.layer.insertSublayer(gradientLayer, at: 0)
        
        saveEditButton.addTarget(self, action: #selector(saveEditInfoTapped), for: .touchUpInside)
    }
    
    // MARK: - User Actions (unchanged)
    @objc private func handleBackgroundTap() {
        view.endEditing(true)
        editInfoBackgroundView.isHidden = true
    }
    
    @objc private func editAccountInfoTapped() {
        editNameTextField.text = (nameLabel.text == "Please Enter name") ? "" : nameLabel.text
        if let currentUserPhone = Auth.auth().currentUser?.phoneNumber, !currentUserPhone.isEmpty {
            editPhoneTextField.text = currentUserPhone
        } else {
            editPhoneTextField.text = (phoneLabel.text == "Please Enter phone number") ? "" : phoneLabel.text?.replacingOccurrences(of: "Phone: ", with: "")
        }
        editInfoBackgroundView.isHidden = false
        editNameTextField.becomeFirstResponder()
    }
    
    @objc private func saveEditInfoTapped() {
        let name = editNameTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let phoneInput = editPhoneTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        
        nameLabel.text = name.isEmpty ? "Please Enter name" : name
        if let currentUserPhone = Auth.auth().currentUser?.phoneNumber, !currentUserPhone.isEmpty {
            phoneLabel.text = "Phone: \(currentUserPhone)"
        } else {
            phoneLabel.text = phoneInput.isEmpty ? "Please Enter phone number" : "Phone: \(phoneInput)"
        }
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        var data: [String: String] = ["name": name]
        if Auth.auth().currentUser?.phoneNumber == nil || Auth.auth().currentUser?.phoneNumber?.isEmpty == true {
            data["phone"] = phoneInput
        }
        Firestore.firestore().collection("users").document(uid).setData(data, merge: true)
        
        editInfoBackgroundView.isHidden = true
        view.endEditing(true)
    }
    
    @objc private func privacyButtonTapped() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }
    
    @objc private func editContactsButtonTapped() {
        let editVC = EditContactViewController()
        navigationController?.pushViewController(editVC, animated: true)
    }
    
    @objc private func logoutButtonTapped() {
        let alert = UIAlertController(title: "Logout", message: "Are you sure?", preferredStyle: .alert)
        
        let titleAttributes = [NSAttributedString.Key.foregroundColor: UIColor(hex: "#40cbd8")]
        let messageAttributes = [NSAttributedString.Key.foregroundColor: UIColor(hex: "#40cbd8")]
        
        let attributedTitle = NSAttributedString(string: "Logout", attributes: titleAttributes)
        let attributedMessage = NSAttributedString(string: "Are you sure?", attributes: messageAttributes)
        
        alert.setValue(attributedTitle, forKey: "attributedTitle")
        alert.setValue(attributedMessage, forKey: "attributedMessage")
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        cancelAction.setValue(UIColor.white, forKey: "titleTextColor")
        
        let logoutAction = UIAlertAction(title: "Logout", style: .destructive) { _ in
            self.performLogout()
        }
        logoutAction.setValue(UIColor.red, forKey: "titleTextColor")
        
        alert.addAction(cancelAction)
        alert.addAction(logoutAction)
        
        if let bgView = alert.view.subviews.first?.subviews.first?.subviews.first {
            bgView.backgroundColor = UIColor(hex: "#222222")
        }
        
        present(alert, animated: true)
    }
    
    // MARK: - Data Handling (unchanged)
    private func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).getDocument { [weak self] snapshot, error in
            guard let data = snapshot?.data(), error == nil else { return }
            
            self?.nameLabel.text = (data["name"] as? String)?.isEmpty ?? true ?
                "Please Enter name" :
                data["name"] as? String
            if let currentUserPhone = Auth.auth().currentUser?.phoneNumber, !currentUserPhone.isEmpty {
                self?.phoneLabel.text = "Phone: \(currentUserPhone)"
            } else if let phone = data["phone"] as? String, !phone.isEmpty {
                self?.phoneLabel.text = "Phone: \(phone)"
            } else {
                self?.phoneLabel.text = "Please Enter phone number"
            }
        }
    }
    
    private func performLogout() {
        do {
            try Auth.auth().signOut()
            let loginVC = LoginPage()
            if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                sceneDelegate.window?.rootViewController = loginVC
                sceneDelegate.window?.makeKeyAndVisible()
            }
        } catch {
            showAlert(title: "Logout Error", message: error.localizedDescription)
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
