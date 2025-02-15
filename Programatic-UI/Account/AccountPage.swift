import UIKit
import FirebaseFirestore
import FirebaseAuth



// MARK: - UITextField Padding Extension
extension UITextField {
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}

// MARK: - AccountPage
class AccountPage: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let infoCardView = UIView()
    private let buttonsCardView = UIView()
    private let nameLabel = UILabel()
    private let phoneLabel = UILabel()
    private let privacyButton = UIButton()
    private let editContactsButton = UIButton()
    private let logoutButton = UIButton()
    
    // MARK: - Edit Info Overlay Components
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
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#222222")
        
        // Scroll View Setup
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
        
        // Info Card Setup
        infoCardView.backgroundColor = UIColor(hex: "#333333")
        infoCardView.layer.cornerRadius = 15
        infoCardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(infoCardView)
        
        nameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        nameLabel.textColor = UIColor(hex: "#40CBD8")
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        phoneLabel.font = UIFont.systemFont(ofSize: 16)
        phoneLabel.textColor = .lightGray
        phoneLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Arrow image with tap gesture.
        let arrowImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrowImageView.tintColor = .white
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        arrowImageView.isUserInteractionEnabled = true
        arrowImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(editAccountInfoTapped)))
        
        infoCardView.addSubview(nameLabel)
        infoCardView.addSubview(phoneLabel)
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
            arrowImageView.trailingAnchor.constraint(equalTo: infoCardView.trailingAnchor, constant: -16)
        ])
        
        // Buttons Card Setup
        buttonsCardView.backgroundColor = UIColor(hex: "#333333")
        buttonsCardView.layer.cornerRadius = 15
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
    
    private func configureButton(_ button: UIButton, title: String, systemImageName: String) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.setImage(UIImage(systemName: systemImageName), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor(hex: "#818589").withAlphaComponent(0.8)
        button.contentHorizontalAlignment = .left
        button.layer.cornerRadius = 12
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
    
    // MARK: - Edit Info Overlay Setup
    private func setupEditInfoView() {
        view.addSubview(editInfoBackgroundView)
        editInfoBackgroundView.addSubview(editInfoContainerView)
        editInfoContainerView.addSubview(editNameTextField)
        editInfoContainerView.addSubview(editPhoneTextField)
        editInfoContainerView.addSubview(saveEditButton)
        
        // Dismiss overlay when background is tapped.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        editInfoBackgroundView.addGestureRecognizer(tapGesture)
        
        NSLayoutConstraint.activate([
            editInfoBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            editInfoBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            editInfoBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            editInfoBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            editInfoContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            editInfoContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            editInfoContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            editInfoContainerView.heightAnchor.constraint(equalToConstant: 200),
            
            editNameTextField.topAnchor.constraint(equalTo: editInfoContainerView.topAnchor, constant: 20),
            editNameTextField.leadingAnchor.constraint(equalTo: editInfoContainerView.leadingAnchor, constant: 20),
            editNameTextField.trailingAnchor.constraint(equalTo: editInfoContainerView.trailingAnchor, constant: -20),
            editNameTextField.heightAnchor.constraint(equalToConstant: 40),
            
            editPhoneTextField.topAnchor.constraint(equalTo: editNameTextField.bottomAnchor, constant: 15),
            editPhoneTextField.leadingAnchor.constraint(equalTo: editInfoContainerView.leadingAnchor, constant: 20),
            editPhoneTextField.trailingAnchor.constraint(equalTo: editInfoContainerView.trailingAnchor, constant: -20),
            editPhoneTextField.heightAnchor.constraint(equalToConstant: 40),
            
            saveEditButton.bottomAnchor.constraint(equalTo: editInfoContainerView.bottomAnchor, constant: -20),
            saveEditButton.trailingAnchor.constraint(equalTo: editInfoContainerView.trailingAnchor, constant: -20),
            saveEditButton.widthAnchor.constraint(equalToConstant: 80),
            saveEditButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Add left padding to the text fields for consistency.
        editNameTextField.setLeftPaddingPoints(10)
        editPhoneTextField.setLeftPaddingPoints(10)
        
        saveEditButton.addTarget(self, action: #selector(saveEditInfoTapped), for: .touchUpInside)
    }
    
    // MARK: - User Actions
    @objc private func handleBackgroundTap() {
        view.endEditing(true)
        editInfoBackgroundView.isHidden = true
    }
    
    @objc private func editAccountInfoTapped() {
        // Pre-populate text fields based on existing labels.
        editNameTextField.text = (nameLabel.text == "Please Enter name") ? "" : nameLabel.text
        
        // Use the phone number from login credentials if available.
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
        
        // Update the name label with validation.
        nameLabel.text = name.isEmpty ? "Please Enter name" : name
        
        // Instead of saving the phone number entered here,
        // always display the phone number from the login credentials on the info card view.
        if let currentUserPhone = Auth.auth().currentUser?.phoneNumber, !currentUserPhone.isEmpty {
            phoneLabel.text = "Phone: \(currentUserPhone)"
        } else {
            phoneLabel.text = phoneInput.isEmpty ? "Please Enter phone number" : "Phone: \(phoneInput)"
        }
        
        // Update Firestore:
        // Always update the name.
        // Update the phone only if there is no phone number in the login credentials.
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
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { _ in
            self.performLogout()
        })
        present(alert, animated: true)
    }
    
    // MARK: - Data Handling
    private func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).getDocument { [weak self] snapshot, error in
            guard let data = snapshot?.data(), error == nil else { return }
            
            self?.nameLabel.text = (data["name"] as? String)?.isEmpty ?? true ?
                "Please Enter name" :
                data["name"] as? String
            
            // Display the phone number from login credentials if available;
            // otherwise, fallback to the saved phone number.
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
            
            // Update root view controller (adjust for your SceneDelegate setup)
            if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                sceneDelegate.window?.rootViewController = loginVC
                sceneDelegate.window?.makeKeyAndVisible()
            }
        } catch {
            showAlert(title: "Logout Error", message: error.localizedDescription)
        }
    }
    
    // MARK: - Helpers
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
