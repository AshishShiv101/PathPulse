import UIKit
import FirebaseFirestore
import FirebaseAuth
import CoreLocation

extension UITextField {
    func setLeftPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}

class AccountPage: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let infoCardView = UIView()
    private let buttonsCardView = UIView()
    private let nameLabel = UILabel()
    private let phoneLabel = UILabel()
    private let privacyButton = UIButton()
    private let editContactsButton = UIButton()
    private let logoutButton = UIButton()
    private let deleteAccountButton = UIButton()
    private let locationManager = CLLocationManager()
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = UIColor(hex: "#40CBD8")
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
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
        tf.attributedPlaceholder = NSAttributedString(
            string: placeholderText,
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
        )
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
        tf.attributedPlaceholder = NSAttributedString(
            string: placeholderText,
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
        )
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
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupEditInfoView()
        setupActivityIndicator()
        setupKeyboardObservers()
        fetchUserData()
        editPhoneTextField.delegate = self
        locationManager.delegate = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        requestLocationPermission()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkAndPromptForName()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGradientLayers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#222222")
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

        infoCardView.backgroundColor = UIColor(hex: "#333333")
        infoCardView.layer.cornerRadius = 20
        infoCardView.layer.masksToBounds = true
        infoCardView.layer.shadowColor = UIColor.black.cgColor
        infoCardView.layer.shadowOpacity = 0.2
        infoCardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        infoCardView.layer.shadowRadius = 8
        infoCardView.translatesAutoresizingMaskIntoConstraints = false

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor(hex: "#333333").cgColor, UIColor(hex: "#2A2A2A").cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.name = "infoCardGradient"
        infoCardView.layer.insertSublayer(gradientLayer, at: 0)

        contentView.addSubview(infoCardView)

        nameLabel.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        nameLabel.textColor = UIColor(hex: "#40CBD8")
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.accessibilityLabel = "User name"

        phoneLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        phoneLabel.textColor = .lightGray
        phoneLabel.translatesAutoresizingMaskIntoConstraints = false
        phoneLabel.accessibilityLabel = "Phone number"

        let editIconView = UIImageView(image: UIImage(systemName: "pencil")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 25, weight: .semibold)))
        editIconView.tintColor = UIColor(hex: "#40CBD8")
        editIconView.translatesAutoresizingMaskIntoConstraints = false
        editIconView.isUserInteractionEnabled = true
        editIconView.accessibilityLabel = "Edit profile"
        editIconView.accessibilityTraits = .button
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

        buttonsCardView.backgroundColor = UIColor(hex: "#333333")
        buttonsCardView.layer.cornerRadius = 20
        buttonsCardView.layer.shadowColor = UIColor.black.cgColor
        buttonsCardView.layer.shadowOpacity = 0.2
        buttonsCardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        buttonsCardView.layer.shadowRadius = 8
        buttonsCardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(buttonsCardView)

        configureButton(editContactsButton, title: "Emergency Contacts", systemImageName: "person.2.fill", isHighlighted: true)
        configureButton(privacyButton, title: "Privacy Settings", systemImageName: "lock.fill", isHighlighted: false)
        configureButton(logoutButton, title: "Logout", systemImageName: "arrowshape.turn.up.left.fill", isHighlighted: false)
        configureButton(deleteAccountButton, title: "Delete Account", systemImageName: "trash.fill", isHighlighted: false)

        editContactsButton.addTarget(self, action: #selector(editContactsButtonTapped), for: .touchUpInside)
        privacyButton.addTarget(self, action: #selector(privacyButtonTapped), for: .touchUpInside)
        logoutButton.addTarget(self, action: #selector(logoutButtonTapped), for: .touchUpInside)
        deleteAccountButton.addTarget(self, action: #selector(deleteAccountButtonTapped), for: .touchUpInside)

        let buttonStackView = UIStackView(arrangedSubviews: [editContactsButton, privacyButton, logoutButton, deleteAccountButton])
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
        editNameTextField.accessibilityLabel = "Edit name"
        editPhoneTextField.accessibilityLabel = "Edit phone number"

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor(hex: "#40CBD8").cgColor, UIColor(hex: "#36A8B3").cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.name = "saveButtonGradient"
        saveEditButton.layer.insertSublayer(gradientLayer, at: 0)

        saveEditButton.addTarget(self, action: #selector(saveEditInfoTapped), for: .touchUpInside)
        saveEditButton.accessibilityLabel = "Save changes"
    }

    private func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func configureButton(_ button: UIButton, title: String, systemImageName: String, isHighlighted: Bool) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.setImage(UIImage(systemName: systemImageName)?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)), for: .normal)
        button.tintColor = .white
        button.contentHorizontalAlignment = .left

        if isHighlighted {
            button.backgroundColor = UIColor(hex: "#40CBD8").withAlphaComponent(0.9)
            button.layer.cornerRadius = 16
            button.heightAnchor.constraint(equalToConstant: 60).isActive = true
            button.layer.borderWidth = 1.5
            button.layer.borderColor = UIColor(hex: "#FFFFFF").withAlphaComponent(0.3).cgColor
            button.layer.shadowColor = UIColor(hex: "#40CBD8").cgColor
            button.layer.shadowOpacity = 0.4
            button.layer.shadowOffset = CGSize(width: 0, height: 3)
            button.layer.shadowRadius = 6
        } else {
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

        button.accessibilityLabel = title
    }

    private func updateGradientLayers() {
        if let gradientLayer = infoCardView.layer.sublayers?.first(where: { $0.name == "infoCardGradient" }) as? CAGradientLayer {
            gradientLayer.frame = infoCardView.bounds
        }
        if let gradientLayer = saveEditButton.layer.sublayers?.first(where: { $0.name == "saveButtonGradient" }) as? CAGradientLayer {
            gradientLayer.frame = saveEditButton.bounds
        }
    }

    // MARK: - Action Methods

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardHeight = keyboardFrame.cgRectValue.height
        scrollView.contentInset.bottom = keyboardHeight
        scrollView.scrollIndicatorInsets.bottom = keyboardHeight
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset.bottom = 0
        scrollView.scrollIndicatorInsets.bottom = 0
    }

    @objc private func handleBackgroundTap() {
        view.endEditing(true)
        editInfoBackgroundView.isHidden = true
    }

    @objc private func editAccountInfoTapped() {
        editNameTextField.text = (nameLabel.text == "Please Enter name") ? "" : nameLabel.text
        if let currentUserPhone = Auth.auth().currentUser?.phoneNumber, !currentUserPhone.isEmpty {
            editPhoneTextField.text = String(currentUserPhone.dropFirst(3)) // Remove "+91"
            editPhoneTextField.isEnabled = false
        } else {
            editPhoneTextField.text = (phoneLabel.text == "Please Enter phone number") ? "" : phoneLabel.text?.replacingOccurrences(of: "Phone: ", with: "")
            editPhoneTextField.isEnabled = true
        }
        editInfoBackgroundView.isHidden = false
        editNameTextField.becomeFirstResponder()
    }

    @objc private func saveEditInfoTapped() {
        let name = editNameTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let phoneInput = editPhoneTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""

        if !phoneInput.isEmpty && editPhoneTextField.isEnabled {
            let numericPhone = phoneInput.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            if numericPhone != phoneInput {
                showPhoneValidationAlert(message: "Phone number should only contain digits.")
                return
            }
            if numericPhone.count != 10 {
                showPhoneValidationAlert(message: "Phone number must be exactly 10 digits long.")
                return
            }
        }

        activityIndicator.startAnimating()
        saveEditButton.isEnabled = false

        nameLabel.text = name.isEmpty ? "Please Enter name" : name
        if let currentUserPhone = Auth.auth().currentUser?.phoneNumber, !currentUserPhone.isEmpty {
            phoneLabel.text = "Phone: \(String(currentUserPhone.dropFirst(3)))"
        } else {
            phoneLabel.text = phoneInput.isEmpty ? "Please Enter phone number" : "Phone: \(phoneInput)"
        }

        guard let uid = Auth.auth().currentUser?.uid else {
            activityIndicator.stopAnimating()
            saveEditButton.isEnabled = true
            showAlert(title: "Error", message: "User not authenticated.")
            return
        }

        var data: [String: String] = ["name": name]
        if editPhoneTextField.isEnabled && !phoneInput.isEmpty {
            data["phone"] = phoneInput
        }

        Firestore.firestore().collection("users").document(uid).setData(data, merge: true) { [weak self] error in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            self.saveEditButton.isEnabled = true

            if let error = error {
                self.showAlert(title: "Error", message: "Failed to save data: \(error.localizedDescription)")
            } else {
                self.editInfoBackgroundView.isHidden = true
                self.view.endEditing(true)
            }
        }
    }

    @objc private func privacyButtonTapped() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }

    @objc private func editContactsButtonTapped() {
        let isNameMissing = nameLabel.text == "Please Enter name" || nameLabel.text?.isEmpty == true
        let isPhoneMissing = phoneLabel.text == "Please Enter phone number" || phoneLabel.text?.isEmpty == true || phoneLabel.text == "Phone: "

        if isNameMissing || isPhoneMissing {
            let alert = UIAlertController(
                title: "Information Required",
                message: "Please add your name and phone number in your profile before adding emergency contacts.",
                preferredStyle: .alert
            )

            let titleAttributes = [NSAttributedString.Key.foregroundColor: UIColor(hex: "#40CBD8")]
            let messageAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]

            let attributedTitle = NSAttributedString(string: "Information Required", attributes: titleAttributes)
            let attributedMessage = NSAttributedString(
                string: "Please add your name and phone number in your profile before adding emergency contacts.",
                attributes: messageAttributes
            )

            alert.setValue(attributedTitle, forKey: "attributedTitle")
            alert.setValue(attributedMessage, forKey: "attributedMessage")

            let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                self?.editAccountInfoTapped()
            }
            okAction.setValue(UIColor(hex: "#40CBD8"), forKey: "titleTextColor")

            alert.addAction(okAction)

            if let bgView = alert.view.subviews.first?.subviews.first?.subviews.first {
                bgView.backgroundColor = UIColor(hex: "#333333")
            }

            present(alert, animated: true)
        } else {
            let editVC = EditContactViewController() // Ensure this class exists
            navigationController?.pushViewController(editVC, animated: true)
        }
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

    @objc private func deleteAccountButtonTapped() {
        let alert = UIAlertController(
            title: "Delete Account",
            message: "Are you sure you want to delete your account? This cannot be undone.",
            preferredStyle: .alert
        )

        let titleAttributes = [NSAttributedString.Key.foregroundColor: UIColor(hex: "#40cbd8")]
        let messageAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]

        let attributedTitle = NSAttributedString(string: "Delete Account", attributes: titleAttributes)
        let attributedMessage = NSAttributedString(
            string: "Are you sure you want to delete your account? This cannot be undone.",
            attributes: messageAttributes
        )

        alert.setValue(attributedTitle, forKey: "attributedTitle")
        alert.setValue(attributedMessage, forKey: "attributedMessage")

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        cancelAction.setValue(UIColor.white, forKey: "titleTextColor")

        let deleteAction = UIAlertAction(title: "Yes", style: .destructive) { [weak self] _ in
            self?.performAccountDeletion()
        }
        deleteAction.setValue(UIColor.red, forKey: "titleTextColor")

        alert.addAction(cancelAction)
        alert.addAction(deleteAction)

        if let bgView = alert.view.subviews.first?.subviews.first?.subviews.first {
            bgView.backgroundColor = UIColor(hex: "#222222")
        }

        present(alert, animated: true)
    }

    // MARK: - Data Methods

    private func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else {
            showAlert(title: "Error", message: "User not authenticated.")
            return
        }

        activityIndicator.startAnimating()
        Firestore.firestore().collection("users").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else {
                self?.activityIndicator.stopAnimating()
                return
            }

            self.activityIndicator.stopAnimating()

            if let error = error {
                self.showAlert(title: "Error", message: "Failed to fetch user data: \(error.localizedDescription)")
                return
            }

            let data = snapshot?.data()
            let name = data?["name"] as? String

            // If name exists in Firestore and is not empty, display it; otherwise, set placeholder
            self.nameLabel.text = name?.isEmpty ?? true ? "Please Enter name" : name

            if let currentUserPhone = Auth.auth().currentUser?.phoneNumber, !currentUserPhone.isEmpty {
                self.phoneLabel.text = "Phone: \(String(currentUserPhone.dropFirst(3)))" // Remove "+91"
            } else if let phone = data?["phone"] as? String, !phone.isEmpty {
                self.phoneLabel.text = "Phone: \(phone)"
            } else {
                self.phoneLabel.text = "Please Enter phone number"
            }
        }
    }

    private func checkAndPromptForName() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self, error == nil else { return }
            let data = snapshot?.data()
            let name = data?["name"] as? String

            // Prompt for manual entry if name is nil or empty
            if name == nil || name?.isEmpty == true {
                DispatchQueue.main.async {
                    self.editAccountInfoTapped()
                }
            }
        }
    }

    private func performLogout() {
        do {
            try Auth.auth().signOut()
            let loginVC = LoginPage()
            if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                sceneDelegate.window?.rootViewController = UINavigationController(rootViewController: loginVC)
                sceneDelegate.window?.makeKeyAndVisible()
            }
        } catch {
            showAlert(title: "Logout Error", message: error.localizedDescription)
        }
    }

    private func performAccountDeletion() {
        guard let user = Auth.auth().currentUser else {
            showAlert(title: "Error", message: "No user found to delete.")
            return
        }

        activityIndicator.startAnimating()
        user.getIDTokenForcingRefresh(true) { [weak self] idToken, error in
            guard let self = self else {
                self?.activityIndicator.stopAnimating()
                return
            }

            if let error = error {
                self.activityIndicator.stopAnimating()
                self.showAlert(title: "Authentication Error", message: "Failed to refresh token: \(error.localizedDescription)")
                return
            }

            let uid = user.uid

            // Delete Firestore user data
            Firestore.firestore().collection("users").document(uid).delete { error in
                if let error = error {
                    self.activityIndicator.stopAnimating()
                    self.showAlert(title: "Error", message: "Failed to delete user data: \(error.localizedDescription)")
                    return
                }

                // Delete Firebase Auth account
                user.delete { error in
                    self.activityIndicator.stopAnimating()
                    if let error = error {
                        self.showAlert(title: "Error", message: "Failed to delete account: \(error.localizedDescription)")
                    } else {
                        let loginVC = LoginPage()
                        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                            sceneDelegate.window?.rootViewController = UINavigationController(rootViewController: loginVC)
                            sceneDelegate.window?.makeKeyAndVisible()
                        }
                    }
                }
            }

            // Delete emergency requests (if any)
            Firestore.firestore().collection("emergency_requests").document(uid).delete { error in
                if let error = error {
                    print("Failed to delete emergency request: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Location Methods

    private func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.requestLocation()
        } else if status == .denied || status == .restricted {
            showAlert(title: "Location Permission", message: "Please enable location services in Settings to use emergency features.")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            sendLocationToEmergencyService(location: location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        showAlert(title: "Location Error", message: "Failed to get location: \(error.localizedDescription)")
    }

    private func sendLocationToEmergencyService(location: CLLocation) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let data: [String: Any] = [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "timestamp": FieldValue.serverTimestamp()
        ]

        activityIndicator.startAnimating()
        Firestore.firestore().collection("emergency_requests").document(uid).setData(data) { [weak self] error in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            if let error = error {
                self.showAlert(title: "Error", message: "Failed to send location: \(error.localizedDescription)")
            } else {
                print("Location sent: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            }
        }
    }

    // MARK: - Helper Methods

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showPhoneValidationAlert(message: String) {
        let alert = UIAlertController(
            title: "Invalid Phone Number",
            message: message,
            preferredStyle: .alert
        )

        let titleAttributes = [NSAttributedString.Key.foregroundColor: UIColor(hex: "#40CBD8")]
        let messageAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]

        let attributedTitle = NSAttributedString(string: "Invalid Phone Number", attributes: titleAttributes)
        let attributedMessage = NSAttributedString(string: message, attributes: messageAttributes)

        alert.setValue(attributedTitle, forKey: "attributedTitle")
        alert.setValue(attributedMessage, forKey: "attributedMessage")

        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.editPhoneTextField.becomeFirstResponder()
        }
        okAction.setValue(UIColor(hex: "#40CBD8"), forKey: "titleTextColor")
        alert.addAction(okAction)

        if let bgView = alert.view.subviews.first?.subviews.first?.subviews.first {
            bgView.backgroundColor = UIColor(hex: "#333333")
        }

        present(alert, animated: true)
    }

    // MARK: - UITextFieldDelegate

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == editPhoneTextField {
            let currentText = textField.text ?? ""
            guard let stringRange = Range(range, in: currentText) else { return false }
            let updatedText = currentText.replacingCharacters(in: stringRange, with: string)

            let numericOnly = updatedText.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            return numericOnly.count <= 10 && updatedText == numericOnly
        }
        return true
    }
}
