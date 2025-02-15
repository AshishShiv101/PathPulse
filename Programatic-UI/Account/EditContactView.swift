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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        setupScrollView()
        setupUI()
        loadContactsFromFirebase()
        setupNavigationBarAppearance()
    }

    private func setupNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        
        let viewBackgroundColor = UIColor(hex: "#222222") // अपना व्यू कलर यहां डालें
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
    }
    
    private func configureTitleLabel() {
        let titleLabel = UILabel()
        titleLabel.text = "Emergency Contacts"
        titleLabel.font = UIFont.systemFont(ofSize: 26, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
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
            contactsStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 170),
            contactsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contactsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            contactsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
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
        let deleteButton = createActionButton(icon: "trash.fill", action: #selector(deleteContact), name: title)

        let buttonStack = UIStackView(arrangedSubviews: [callButton, messageButton, deleteButton])
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 15
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView(arrangedSubviews: [nameLabel, phoneLabel, buttonStack])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
            cardView.heightAnchor.constraint(equalToConstant: 140),
            callButton.widthAnchor.constraint(equalToConstant: 48),
            callButton.heightAnchor.constraint(equalToConstant: 48),
            messageButton.widthAnchor.constraint(equalToConstant: 48),
            messageButton.heightAnchor.constraint(equalToConstant: 48),
            deleteButton.widthAnchor.constraint(equalToConstant: 48),
            deleteButton.heightAnchor.constraint(equalToConstant: 48)
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
        
        // Configure symbol image
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        button.setImage(UIImage(systemName: icon, withConfiguration: config), for: .normal)
        
        // Add button action
        button.addTarget(self, action: action, for: .touchUpInside)
        
        // Set size constraints
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 48),  // Increased for circle shape
            button.heightAnchor.constraint(equalToConstant: 48)  // Make it square
        ])
        
        // Set accessibility
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
        let picker = CNContactPickerViewController()
        picker.delegate = self
        picker.displayedPropertyKeys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey]
        present(picker, animated: true)
    }

   
        private func reloadContactCards() {
        contactsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        contacts.sorted(by: { $0.key < $1.key }).forEach { name, phone in
            let card = createContactCard(title: name, phoneNumber: phone)
            contactsStackView.addArrangedSubview(card)
        }
    }
    
    @objc private func addContactTapped() {
        let alert = UIAlertController(title: "Add Contact", message: "Would you like to import a contact from your iPhone?", preferredStyle: .alert)
        
        // Customize the alert title color and background (for dark mode)
        let titleFont = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18), NSAttributedString.Key.foregroundColor: UIColor.white]
        let messageFont = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15), NSAttributedString.Key.foregroundColor: UIColor.lightGray]
        
        let titleAttrString = NSAttributedString(string: "Add Contact", attributes: titleFont)
        let messageAttrString = NSAttributedString(string: "Would you like to import a contact from your iPhone?", attributes: messageFont)
        
        alert.setValue(titleAttrString, forKey: "attributedTitle")
        alert.setValue(messageAttrString, forKey: "attributedMessage")
        
        // Change background color of alert
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
    
    @objc private func deleteContact(_ sender: UIButton) {
        guard let name = sender.accessibilityLabel else { return }
        contacts.removeValue(forKey: name)
        deleteContactFromFirebase(name: name)
        reloadContactCards()
    }
    
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        dismiss(animated: true)
        guard let contact = contact else { return }
        
        let name = [contact.givenName, contact.familyName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        
        guard !name.isEmpty,
              let phone = contact.phoneNumbers.first?.value.stringValue else { return }
        
        contacts[name] = phone
        saveContactToFirebase(name: name, phoneNumber: phone)
        reloadContactCards()
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
        let name = [contact.givenName, contact.familyName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        
        guard !name.isEmpty,
              let phone = contact.phoneNumbers.first?.value.stringValue else { return }
        
        contacts[name] = phone
        saveContactToFirebase(name: name, phoneNumber: phone)
        reloadContactCards()
    }
}
