import UIKit
import ContactsUI
import FirebaseFirestore
import FirebaseAuth

class EditContactViewController: UIViewController, CNContactViewControllerDelegate {
    private var contacts: [String: String] = [:]
    private let db = Firestore.firestore()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var contactsStackView = UIStackView()
    private let noContactsLabel: UILabel = {
        let label = UILabel()
        label.text = "Add Contacts"
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        setupScrollView()
        setupUI()
        loadContactsFromFirebase()
        setupNavigationBarAppearance()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        scrollView.keyboardDismissMode = .onDrag
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func dismissKeyboard(_ gesture: UITapGestureRecognizer) {
        view.endEditing(true)
        if let picker = presentedViewController as? CNContactPickerViewController {
            picker.view.endEditing(true)
        }
        if let manualEntryVC = presentedViewController as? ManualEntryViewController {
            manualEntryVC.view.endEditing(true)
        }
    }
    
    private func setupNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(hex: "#222222")
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: UIColor(hex: "#40CBD8")]
        appearance.backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(hex: "#40CBD8")]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = UIColor(hex: "#40CBD8")
        navigationController?.navigationBar.isTranslucent = false
    }
    
    private func configureView() {
        view.backgroundColor = UIColor(named: "darkBackground") ?? UIColor(hex: "#222222")
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
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])
    }
    
    private func setupUI() {
        configureTitleLabel()
        configureAddButton()
        configureContactsStack()
        contentView.addSubview(noContactsLabel)
        NSLayoutConstraint.activate([
            noContactsLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            noContactsLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 200)
        ])
    }
    
    private func configureTitleLabel() {
        let titleLabel = UILabel()
        titleLabel.text = "Emergency Contacts"
        titleLabel.font = UIFont.systemFont(ofSize: 26, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        let reminderLabel = UILabel()
        reminderLabel.text = "Long press a contact to delete"
        reminderLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        reminderLabel.textColor = .lightGray
        reminderLabel.textAlignment = .center
        reminderLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(reminderLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            reminderLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            reminderLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }
    
    private func configureAddButton() {
        let addButton = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        let image = UIImage(systemName: "plus", withConfiguration: config)
        addButton.setImage(image, for: .normal)
        addButton.tintColor = .white
        addButton.backgroundColor = UIColor(hex: "#40CBD8")
        addButton.layer.cornerRadius = 30
        addButton.clipsToBounds = true
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(addContactTapped), for: .touchUpInside)
        addButton.contentHorizontalAlignment = .center
        addButton.contentVerticalAlignment = .center
        addButton.imageView?.contentMode = .scaleAspectFit
        view.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            addButton.widthAnchor.constraint(equalToConstant: 60),
            addButton.heightAnchor.constraint(equalToConstant: 60),
            addButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func configureContactsStack() {
        contactsStackView.axis = .vertical
        contactsStackView.spacing = 16
        contactsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(contactsStackView)
        
        NSLayoutConstraint.activate([
            contactsStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 80),
            contactsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contactsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            contactsStackView.bottomAnchor.constraint(greaterThanOrEqualTo: contentView.bottomAnchor, constant: -80)
        ])
        
        contentView.bottomAnchor.constraint(greaterThanOrEqualTo: contactsStackView.bottomAnchor, constant: 80).isActive = true
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            guard let cardView = gesture.view,
                  let mainStack = cardView.subviews.first as? UIStackView,
                  let topStack = mainStack.arrangedSubviews.first as? UIStackView,
                  let nameLabel = topStack.arrangedSubviews.first as? UILabel,
                  let name = nameLabel.text else { return }
            
            let alert = createDarkModeAlert(
                title: "Delete Contact",
                message: "Are you sure you want to delete \(name)? This action cannot be undone."
            )
            
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
                self.contacts.removeValue(forKey: name)
                self.deleteContactFromFirebase(name: name)
                self.reloadContactCards()
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            deleteAction.setValue(UIColor.red, forKey: "titleTextColor")
            cancelAction.setValue(UIColor(hex: "#40CBD8"), forKey: "titleTextColor")
            
            alert.addAction(deleteAction)
            alert.addAction(cancelAction)
            
            present(alert, animated: true)
        }
    }
    
    private func createContactCard(title: String, phoneNumber: String) -> UIView {
        let cardView = UIView()
        cardView.backgroundColor = UIColor(hex: "#1E1E1E")
        cardView.layer.cornerRadius = 15
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.3
        cardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        let nameLabel = UILabel()
        nameLabel.text = title
        nameLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        nameLabel.textColor = .white
        
        let phoneLabel = UILabel()
        phoneLabel.text = phoneNumber
        phoneLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        phoneLabel.textColor = .lightGray
        
        let callButton = createActionButton(icon: "phone.fill", action: #selector(makeCall), phone: phoneNumber)
        let messageButton = createActionButton(icon: "message.fill", action: #selector(sendMessage), phone: phoneNumber)
        
        let buttonStack = UIStackView(arrangedSubviews: [callButton, messageButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.alignment = .trailing
        
        let topStack = UIStackView(arrangedSubviews: [nameLabel, buttonStack])
        topStack.axis = .horizontal
        topStack.alignment = .center
        topStack.spacing = 12
        topStack.distribution = .fill
        
        let mainStack = UIStackView(arrangedSubviews: [topStack, phoneLabel])
        mainStack.axis = .vertical
        mainStack.spacing = 10
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        cardView.addSubview(mainStack)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        cardView.addGestureRecognizer(longPress)
        cardView.isUserInteractionEnabled = true
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            mainStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
            
            callButton.widthAnchor.constraint(equalToConstant: 48),
            callButton.heightAnchor.constraint(equalToConstant: 48),
            messageButton.widthAnchor.constraint(equalToConstant: 48),
            messageButton.heightAnchor.constraint(equalToConstant: 48)
        ])
        
        return cardView
    }
    
    @objc private func makeCall(_ sender: UIButton) {
        guard let phoneNumber = sender.accessibilityIdentifier,
              let url = URL(string: "tel://\(phoneNumber)") else {
            print("Invalid phone number")
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            print("Calling is not supported on this device")
        }
    }
    
    private func createActionButton(icon: String, action: Selector, phone: String? = nil, name: String? = nil) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(hex: "#40CBD8").withAlphaComponent(0.8)
        button.layer.cornerRadius = 24
        button.tintColor = .white
        button.clipsToBounds = true
        
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        button.setImage(UIImage(systemName: icon, withConfiguration: config), for: .normal)
        
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        if let phone = phone {
            button.accessibilityIdentifier = phone
        }
        if let name = name {
            button.accessibilityLabel = name
        }
        
        return button
    }
    
    private func loadContactsFromFirebase() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).collection("contacts")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching contacts: \(error.localizedDescription)")
                    return
                }
                
                self.contacts.removeAll()
                snapshot?.documents.forEach { document in
                    let data = document.data()
                    if let name = data["name"] as? String, let phone = data["phone"] as? String {
                        self.contacts[name] = phone
                    }
                }
                
                self.reloadContactCards()
            }
    }
    
    private func saveContactToFirebase(name: String, phoneNumber: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).collection("contacts").document(name)
            .setData(["name": name, "phone": phoneNumber]) { error in
                if let error = error {
                    print("Error saving contact: \(error.localizedDescription)")
                }
            }
    }
    
    private func deleteContactFromFirebase(name: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).collection("contacts").document(name)
            .delete { error in
                if let error = error {
                    print("Error deleting contact: \(error.localizedDescription)")
                }
            }
    }
    
    func showContactPicker() {
        let picker = CustomContactPickerViewController()
        picker.delegate = self
        picker.displayedPropertyKeys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey]
        picker.modalPresentationStyle = .fullScreen
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        picker.view.addGestureRecognizer(tap)
        
        present(picker, animated: true)
    }
    
    private func reloadContactCards() {
        contactsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if contacts.isEmpty {
            noContactsLabel.isHidden = false
        } else {
            noContactsLabel.isHidden = true
            let sortedContacts = contacts.sorted(by: { $0.key < $1.key })
            sortedContacts.enumerated().forEach { index, element in
                let (name, phone) = element
                let card = createContactCard(title: name, phoneNumber: phone)
                contactsStackView.addArrangedSubview(card)
            }
        }
        
        view.layoutIfNeeded()
    }
    
    @objc private func addContactTapped() {
        let alert = createDarkModeAlert(
            title: "Add Contact",
            message: "Would you like to import a contact from your iPhone?"
        )
        
        let importAction = UIAlertAction(title: "Import from Contacts", style: .default) { _ in
            self.showContactPicker()
        }
        let manualAction = UIAlertAction(title: "Enter Manually", style: .default) { _ in
            self.showManualEntryViewController()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        importAction.setValue(UIColor(hex: "#40CBD8"), forKey: "titleTextColor")
        manualAction.setValue(UIColor(hex: "#40CBD8"), forKey: "titleTextColor")
        cancelAction.setValue(UIColor.red, forKey: "titleTextColor")
        
        alert.addAction(importAction)
        alert.addAction(manualAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func showManualEntryViewController() {
        let manualEntryVC = ManualEntryViewController()
        manualEntryVC.delegate = self
        manualEntryVC.modalPresentationStyle = .overCurrentContext
        present(manualEntryVC, animated: true)
    }
    
    private func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        let phoneRegex = "^[0-9]{8,15}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phoneTest.evaluate(with: phoneNumber)
    }
    
    @objc private func sendMessage(_ sender: UIButton) {
        guard let phoneNumber = sender.accessibilityIdentifier,
              let url = URL(string: "sms:\(phoneNumber)"),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
    
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        dismiss(animated: true)
    }
    
    private func createDarkModeAlert(title: String, message: String?) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let titleFont = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18),
                        NSAttributedString.Key.foregroundColor: UIColor.white]
        let messageFont = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15),
                         NSAttributedString.Key.foregroundColor: UIColor.lightGray]
        
        let titleAttrString = NSAttributedString(string: title, attributes: titleFont)
        let messageAttrString = message.map { NSAttributedString(string: $0, attributes: messageFont) }
        
        alert.setValue(titleAttrString, forKey: "attributedTitle")
        if let messageAttrString = messageAttrString {
            alert.setValue(messageAttrString, forKey: "attributedMessage")
        }
        
        alert.view.subviews.first?.subviews.first?.subviews.first?.backgroundColor = UIColor(hex: "#1E1E1E")
        alert.overrideUserInterfaceStyle = .dark
        
        return alert
    }
    
    private func showValidationAlert(message: String) {
        let alert = createDarkModeAlert(title: "Invalid Contact", message: message)
        
        let okAction = UIAlertAction(title: "OK", style: .default)
        okAction.setValue(UIColor(hex: "#40CBD8"), forKey: "titleTextColor")
        alert.addAction(okAction)
        
        present(alert, animated: true)
    }
}

extension EditContactViewController: ManualEntryViewControllerDelegate {
    func didAddContact(name: String, phoneNumber: String) {
        processContact(name: name, phoneNumber: phoneNumber)
    }
    
    func didCancel() {}
}

extension EditContactViewController: CNContactPickerDelegate {
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        picker.dismiss(animated: true)
        
        let nameComponents = [contact.givenName, contact.familyName].filter { !$0.isEmpty }
        let name = nameComponents.isEmpty ? "Unnamed Contact" : nameComponents.joined(separator: " ")
        
        guard !contact.phoneNumbers.isEmpty else {
            showValidationAlert(message: "Selected contact has no phone number.")
            return
        }
        
        if contact.phoneNumbers.count == 1 {
            let phoneNumber = contact.phoneNumbers.first!.value.stringValue
            let numericPhone = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            processContact(name: name, phoneNumber: numericPhone)
        } else {
            let alert = createDarkModeAlert(
                title: "Select Phone Number",
                message: "This contact has multiple phone numbers. Please choose one."
            )
            
            for phone in contact.phoneNumbers {
                let phoneNumber = phone.value.stringValue
                let numericPhone = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                let action = UIAlertAction(title: phoneNumber, style: .default) { _ in
                    self.processContact(name: name, phoneNumber: numericPhone)
                }
                action.setValue(UIColor(hex: "#40CBD8"), forKey: "titleTextColor")
                alert.addAction(action)
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            cancelAction.setValue(UIColor.red, forKey: "titleTextColor")
            alert.addAction(cancelAction)
            
            present(alert, animated: true)
        }
    }
    
    private func processContact(name: String, phoneNumber: String) {
        if phoneNumber.isEmpty {
            showValidationAlert(message: "Phone number cannot be empty.")
            return
        }
        
        if isValidPhoneNumber(phoneNumber) {
            contacts[name] = phoneNumber
            saveContactToFirebase(name: name, phoneNumber: phoneNumber)
            reloadContactCards()
        } else {
            showValidationAlert(message: "Please enter a valid phone number (8-15 digits).")
        }
    }
}

class CustomContactPickerViewController: CNContactPickerViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)

        disableContentInsetAdjustment(for: view)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = false
        }
    }

    private func disableContentInsetAdjustment(for view: UIView) {
        if #available(iOS 11.0, *) {
            if let scrollView = view as? UIScrollView {
                scrollView.contentInsetAdjustmentBehavior = .never
            }
        }
        for subview in view.subviews {
            disableContentInsetAdjustment(for: subview)
        }
    }
}

protocol ManualEntryViewControllerDelegate: AnyObject {
    func didAddContact(name: String, phoneNumber: String)
    func didCancel()
}

class ManualEntryViewController: UIViewController {
    weak var delegate: ManualEntryViewControllerDelegate?
    
    private let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#1E1E1E")
        view.layer.cornerRadius = 15
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Add New Contact"
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Name"
        textField.textColor = .white
        textField.backgroundColor = UIColor(hex: "#2E2E2E")
        textField.layer.cornerRadius = 8
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        textField.leftViewMode = .always
        textField.returnKeyType = .next
        textField.clearButtonMode = .whileEditing
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let phoneTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Phone Number"
        textField.keyboardType = .phonePad
        textField.textColor = .white
        textField.backgroundColor = UIColor(hex: "#2E2E2E")
        textField.layer.cornerRadius = 8
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        textField.leftViewMode = .always
        textField.returnKeyType = .done
        textField.clearButtonMode = .whileEditing
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add", for: .normal)
        button.setTitleColor(UIColor(hex: "#40CBD8"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardHandling()
        nameTextField.delegate = self
        phoneTextField.delegate = self
    }
    
    private func setupUI() {
        view.addSubview(backgroundView)
        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(nameTextField)
        containerView.addSubview(phoneTextField)
        containerView.addSubview(cancelButton)
        containerView.addSubview(addButton)
        
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        backgroundView.addGestureRecognizer(tap)
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 300),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            nameTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            nameTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            nameTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            nameTextField.heightAnchor.constraint(equalToConstant: 40),
            
            phoneTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 15),
            phoneTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            phoneTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            phoneTextField.heightAnchor.constraint(equalToConstant: 40),
            
            cancelButton.topAnchor.constraint(equalTo: phoneTextField.bottomAnchor, constant: 20),
            cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            
            addButton.topAnchor.constraint(equalTo: phoneTextField.bottomAnchor, constant: 20),
            addButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let keyboardHeight = keyboardFrame.height
        let containerBottom = containerView.frame.maxY
        let visibleHeight = view.frame.height - keyboardHeight
        
        if containerBottom > visibleHeight {
            let offset = containerBottom - visibleHeight + 20
            containerView.transform = CGAffineTransform(translationX: 0, y: -offset)
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        containerView.transform = .identity
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true) {
            self.delegate?.didCancel()
        }
    }
    
    @objc private func addTapped() {
        guard let name = nameTextField.text, !name.isEmpty,
              let phone = phoneTextField.text, !phone.isEmpty else {
            let alert = UIAlertController(title: "Invalid Contact", message: "Both name and phone number are required.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let numericPhone = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if numericPhone.count >= 8 && numericPhone.count <= 15 {
            dismiss(animated: true) {
                self.delegate?.didAddContact(name: name, phoneNumber: numericPhone)
            }
        } else {
            let alert = UIAlertController(title: "Invalid Contact", message: "Please enter a valid phone number (8-15 digits).", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
}

extension ManualEntryViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            phoneTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}
