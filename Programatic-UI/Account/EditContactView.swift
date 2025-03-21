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
        
        // Add tap gesture to dismiss keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false // Allow other interactions to pass through
        view.addGestureRecognizer(tap)
        
        // Keyboard observers
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
        // If a contact picker is presented, dismiss its keyboard as well
        if let picker = presentedViewController as? CNContactPickerViewController {
            picker.view.endEditing(true)
        }
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        let keyboardHeight = keyboardFrame.height
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        
        // Adjust the scrollView's content inset to account for the keyboard
        UIView.animate(withDuration: duration) {
            self.scrollView.contentInset = contentInsets
            self.scrollView.scrollIndicatorInsets = contentInsets
        }
        
        // If the contact picker is presented, ensure it adjusts its own content
        if let picker = presentedViewController as? CNContactPickerViewController {
            picker.view.setNeedsLayout()
            picker.view.layoutIfNeeded()
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        let contentInsets = UIEdgeInsets.zero
        
        // Reset the scrollView's content inset
        UIView.animate(withDuration: duration) {
            self.scrollView.contentInset = contentInsets
            self.scrollView.scrollIndicatorInsets = contentInsets
        }
        
        // If the contact picker is presented, ensure it adjusts its own content
        if let picker = presentedViewController as? CNContactPickerViewController {
            picker.view.setNeedsLayout()
            picker.view.layoutIfNeeded()
        }
    }
    
    private func setupNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        let viewBackgroundColor = UIColor(hex: "#222222")
        appearance.backgroundColor = viewBackgroundColor
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
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
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
        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton.tintColor = .white
        addButton.backgroundColor = UIColor(hex: "#40CBD8")
        addButton.layer.cornerRadius = 30
        addButton.clipsToBounds = true
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(addContactTapped), for: .touchUpInside)
        view.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            addButton.widthAnchor.constraint(equalToConstant: 60),
            addButton.heightAnchor.constraint(equalToConstant: 60),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
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
            contactsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            guard let cardView = gesture.view,
                  let mainStack = cardView.subviews.first as? UIStackView,
                  let topStack = mainStack.arrangedSubviews.first as? UIStackView,
                  let nameLabel = topStack.arrangedSubviews.first as? UILabel,
                  let name = nameLabel.text else { return }
            
            let alert = UIAlertController(
                title: "Delete Contact",
                message: "Are you sure you want to delete \(name)? This action cannot be undone.",
                preferredStyle: .alert
            )
            
            let titleFont = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18),
                             NSAttributedString.Key.foregroundColor: UIColor.white]
            let messageFont = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15),
                              NSAttributedString.Key.foregroundColor: UIColor.lightGray]
            
            let titleAttrString = NSAttributedString(string: "Delete Contact", attributes: titleFont)
            let messageAttrString = NSAttributedString(string: "Are you sure you want to delete \(name)? This action cannot be undone.",
                                                      attributes: messageFont)
            
            alert.setValue(titleAttrString, forKey: "attributedTitle")
            alert.setValue(messageAttrString, forKey: "attributedMessage")
            alert.view.subviews.first?.subviews.first?.subviews.first?.backgroundColor = UIColor(hex: "#1E1E1E")
            
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
                
                print("Loaded contacts from Firebase: \(self.contacts)")
                self.reloadContactCards()
            }
    }
    
    private func saveContactToFirebase(name: String, phoneNumber: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).collection("contacts").document(name)
            .setData(["name": name, "phone": phoneNumber]) { error in
                if let error = error {
                    print("Error saving contact: \(error.localizedDescription)")
                } else {
                    print("Successfully saved contact: \(name) - \(phoneNumber)")
                }
            }
    }
    
    private func deleteContactFromFirebase(name: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).collection("contacts").document(name)
            .delete { error in
                if let error = error {
                    print("Error deleting contact: \(error.localizedDescription)")
                } else {
                    print("Successfully deleted contact: \(name)")
                }
            }
    }
    
    func showContactPicker() {
        let picker = CNContactPickerViewController()
        picker.delegate = self
        picker.displayedPropertyKeys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey]
        
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true) {
            picker.view.superview?.clipsToBounds = false
            // Ensure the picker's view can handle keyboard adjustments
            picker.view.setNeedsLayout()
            picker.view.layoutIfNeeded()
        }
    }
    
    private func reloadContactCards() {
        contactsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if contacts.isEmpty {
            noContactsLabel.isHidden = false
        } else {
            noContactsLabel.isHidden = true
            contacts.sorted(by: { $0.key < $1.key }).forEach { name, phone in
                let card = createContactCard(title: name, phoneNumber: phone)
                contactsStackView.addArrangedSubview(card)
            }
        }
    }
    
    @objc private func addContactTapped() {
        let alert = UIAlertController(title: "Add Contact", message: "Would you like to import a contact from your iPhone?", preferredStyle: .alert)
        
        let titleFont = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18), NSAttributedString.Key.foregroundColor: UIColor.white]
        let messageFont = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15), NSAttributedString.Key.foregroundColor: UIColor.lightGray]
        
        let titleAttrString = NSAttributedString(string: "Add Contact", attributes: titleFont)
        let messageAttrString = NSAttributedString(string: "Would you like to import a contact from your iPhone?", attributes: messageFont)
        
        alert.setValue(titleAttrString, forKey: "attributedTitle")
        alert.setValue(messageAttrString, forKey: "attributedMessage")
        
        alert.view.subviews.first?.subviews.first?.subviews.first?.backgroundColor = UIColor(hex: "#1E1E1E")
        
        let importAction = UIAlertAction(title: "Import from Contacts", style: .default) { _ in
            self.showContactPicker()
        }
        let manualAction = UIAlertAction(title: "Enter Manually", style: .default) { _ in
            let contactVC = CNContactViewController(forNewContact: nil)
            contactVC.delegate = self
            let navController = UINavigationController(rootViewController: contactVC)
            self.present(navController, animated: true)
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
    
    @objc private func sendMessage(_ sender: UIButton) {
        guard let phoneNumber = sender.accessibilityIdentifier,
              let url = URL(string: "sms:\(phoneNumber)"),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
    
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        dismiss(animated: true)
        guard let contact = contact else { return }
        
        let name = [contact.givenName, contact.familyName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        
        guard !name.isEmpty,
              let phone = contact.phoneNumbers.first?.value.stringValue else {
            showValidationAlert(message: "Contact must have a name and phone number.")
            return
        }
        
        let numericPhone = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        processContact(name: name, phoneNumber: numericPhone)
    }
    
    private func showValidationAlert(message: String) {
        let alert = UIAlertController(
            title: "Invalid Contact",
            message: message,
            preferredStyle: .alert
        )
        
        let titleFont = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18),
                         NSAttributedString.Key.foregroundColor: UIColor.white]
        let messageFont = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15),
                          NSAttributedString.Key.foregroundColor: UIColor.lightGray]
        
        let titleAttrString = NSAttributedString(string: "Invalid Contact", attributes: titleFont)
        let messageAttrString = NSAttributedString(string: message, attributes: messageFont)
        
        alert.setValue(titleAttrString, forKey: "attributedTitle")
        alert.setValue(messageAttrString, forKey: "attributedMessage")
        alert.view.subviews.first?.subviews.first?.subviews.first?.backgroundColor = UIColor(hex: "#1E1E1E")
        
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            let contactVC = CNContactViewController(forNewContact: nil)
            contactVC.delegate = self
            let navController = UINavigationController(rootViewController: contactVC)
            self.present(navController, animated: true)
        }
        
        okAction.setValue(UIColor(hex: "#40CBD8"), forKey: "titleTextColor")
        alert.addAction(okAction)
        
        present(alert, animated: true)
    }
    
    private func addLogoutButton() {
        let button = UIButton(type: .system)
        button.setTitle("Logout", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleLogout), for: .touchUpInside)
        view.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    @objc private func handleLogout() {
        do {
            try Auth.auth().signOut()
            let loginVC = LoginPage()
            loginVC.modalPresentationStyle = .fullScreen
            present(loginVC, animated: true)
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

extension EditContactViewController: CNContactPickerDelegate {
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        let nameComponents = [contact.givenName, contact.familyName].filter { !$0.isEmpty }
        let name = nameComponents.isEmpty ? "Unnamed Contact" : nameComponents.joined(separator: " ")
        
        print("Selected Contact Name: \(name)")
        print("Phone Numbers Available: \(contact.phoneNumbers.map { $0.value.stringValue })")
        
        guard !contact.phoneNumbers.isEmpty else {
            print("No phone numbers found for \(name)")
            showValidationAlert(message: "Selected contact has no phone number.")
            return
        }
        
        var selectedPhone: String
        if contact.phoneNumbers.count == 1 {
            selectedPhone = contact.phoneNumbers.first!.value.stringValue
            print("Single phone number selected: \(selectedPhone)")
        } else {
            let alert = UIAlertController(
                title: "Select Phone Number",
                message: "This contact has multiple phone numbers. Please choose one.",
                preferredStyle: .actionSheet
            )
            
            for phone in contact.phoneNumbers {
                let phoneNumber = phone.value.stringValue
                let numericPhone = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                let action = UIAlertAction(title: phoneNumber, style: .default) { _ in
                    self.processContact(name: name, phoneNumber: numericPhone)
                }
                alert.addAction(action)
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true)
            return
        }
        
        let numericPhone = selectedPhone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        processContact(name: name, phoneNumber: numericPhone)
    }
    
    private func processContact(name: String, phoneNumber: String) {
        print("Processing Contact - Name: \(name), Phone: \(phoneNumber), Length: \(phoneNumber.count)")
        
        if phoneNumber.isEmpty {
            showValidationAlert(message: "Phone number cannot be empty.")
            return
        }
        
        contacts[name] = phoneNumber
        saveContactToFirebase(name: name, phoneNumber: phoneNumber)
        reloadContactCards()
    }
}
