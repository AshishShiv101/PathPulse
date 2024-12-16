import UIKit
import ContactsUI

class EditContactViewController: UIViewController {
    private var contacts: [String: String] = [:] // Store name and phone number

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "darkBackground") ?? UIColor(hex: "#222222")

        loadSavedContacts()
        setupUI()
    }

    private func setupUI() {
        // Title Label
        let titleLabel = UILabel()
        titleLabel.text = "Emergency Contacts"
        titleLabel.font = UIFont.systemFont(ofSize: 26, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // Stack View
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        // Add Contact Button
        let addContactButton = UIButton(type: .system)
        addContactButton.setTitle("Add Contact", for: .normal)
        addContactButton.setTitleColor(.black, for: .normal)
        addContactButton.backgroundColor = UIColor(named: "buttonColor") ?? UIColor(hex: "#40cbd8")
        addContactButton.layer.cornerRadius = 25
        addContactButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        addContactButton.translatesAutoresizingMaskIntoConstraints = false
        addContactButton.addTarget(self, action: #selector(addContactTapped), for: .touchUpInside)

        view.addSubview(stackView)
        view.addSubview(addContactButton)
        view.addSubview(titleLabel)

        for (name, phone) in contacts {
            let contactCard = createContactCard(title: name, phoneNumber: phone)
            stackView.addArrangedSubview(contactCard)
        }

        // Layout Constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            addContactButton.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 30),
            addContactButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            addContactButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            addContactButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func createContactCard(title: String, phoneNumber: String) -> UIView {
        let cardView = UIView()
        cardView.backgroundColor = UIColor(named: "inputBackground") ?? UIColor.darkGray
        cardView.layer.cornerRadius = 12
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.heightAnchor.constraint(equalToConstant: 140).isActive = true

        // Name Label
        let nameLabel = UILabel()
        nameLabel.text = title
        nameLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        nameLabel.textColor = .white
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        // Phone Number Label
        let phoneLabel = UILabel()
        phoneLabel.text = phoneNumber
        phoneLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        phoneLabel.textColor = .lightGray
        phoneLabel.translatesAutoresizingMaskIntoConstraints = false

        // Call Button
        // Call Button
        let callButton = UIButton(type: .system)
           callButton.setImage(UIImage(systemName: "phone.fill"), for: .normal)
           callButton.tintColor = .white
           callButton.backgroundColor = UIColor(hex: "#40CBD8") // Set the background color
           callButton.layer.cornerRadius = 20 // Make the button circular
           callButton.layer.masksToBounds = true // Ensure the corner radius applies
           callButton.translatesAutoresizingMaskIntoConstraints = false
           callButton.addAction(UIAction { [weak self] _ in
               self?.makeCall(to: phoneNumber)
           }, for: .touchUpInside)

           // Message Button
           let messageButton = UIButton(type: .system)
           messageButton.setImage(UIImage(systemName: "message.fill"), for: .normal)
           messageButton.tintColor = .white
           messageButton.backgroundColor = UIColor(hex: "#40CBD8") // Set the background color
           messageButton.layer.cornerRadius = 20 // Make the button circular
           messageButton.layer.masksToBounds = true // Ensure the corner radius applies
           messageButton.translatesAutoresizingMaskIntoConstraints = false
           messageButton.addAction(UIAction { [weak self] _ in
               self?.sendMessage(to: phoneNumber)
           }, for: .touchUpInside)

           // Delete Button
           let deleteButton = UIButton(type: .system)
           deleteButton.setImage(UIImage(systemName: "trash.fill"), for: .normal)
           deleteButton.tintColor = .white
           deleteButton.backgroundColor = UIColor(hex: "#40CBD8") // Set the background color
           deleteButton.layer.cornerRadius = 20 // Make the button circular
           deleteButton.layer.masksToBounds = true // Ensure the corner radius applies
           deleteButton.translatesAutoresizingMaskIntoConstraints = false
           deleteButton.addAction(UIAction { [weak self] _ in
               self?.deleteContact(name: title, cardView: cardView)
           }, for: .touchUpInside)

        // Add Subviews
        cardView.addSubview(nameLabel)
        cardView.addSubview(phoneLabel)
        cardView.addSubview(callButton)
        cardView.addSubview(messageButton)
        cardView.addSubview(deleteButton)

        // Layout Constraints
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),

            phoneLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            phoneLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),

            callButton.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            callButton.topAnchor.constraint(equalTo: phoneLabel.bottomAnchor, constant: 16),
            callButton.widthAnchor.constraint(equalToConstant: 40),
            callButton.heightAnchor.constraint(equalToConstant: 40),

            messageButton.leadingAnchor.constraint(equalTo: callButton.trailingAnchor, constant: 16),
            messageButton.centerYAnchor.constraint(equalTo: callButton.centerYAnchor),
            messageButton.widthAnchor.constraint(equalToConstant: 40),
            messageButton.heightAnchor.constraint(equalToConstant: 40),

            deleteButton.leadingAnchor.constraint(equalTo: messageButton.trailingAnchor, constant: 16),
            deleteButton.centerYAnchor.constraint(equalTo: callButton.centerYAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 40),
            deleteButton.heightAnchor.constraint(equalToConstant: 40)
        ])

        return cardView
    }

    // Helper Functions
    private func makeCall(to phoneNumber: String) {
        guard !phoneNumber.isEmpty,
              let url = URL(string: "tel://\(phoneNumber)") else {
            print("Invalid phone number")
            return
        }

        if UIApplication.shared.canOpenURL(url) {
            DispatchQueue.main.async {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        } else {
            print("This device cannot make calls.")
        }
    }


    private func sendMessage(to phoneNumber: String) {
        guard let url = URL(string: "sms:\(phoneNumber)"), UIApplication.shared.canOpenURL(url) else {
            print("Invalid phone number or unable to open the SMS app.")
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }


    private func deleteContact(name: String, cardView: UIView) {
        contacts.removeValue(forKey: name)
        saveContacts()
        cardView.removeFromSuperview()
    }


    @objc private func addContactTapped() {
        let contactViewController = CNContactViewController(forNewContact: nil)
        contactViewController.delegate = self
        let navigationController = UINavigationController(rootViewController: contactViewController)
        present(navigationController, animated: true, completion: nil)
    }

    private func addNewContactCard(name: String, phoneNumber: String) {
        contacts[name] = phoneNumber
        saveContacts()
        if let stackView = view.subviews.first(where: { $0 is UIStackView }) as? UIStackView {
            let newContactCard = createContactCard(title: name, phoneNumber: phoneNumber)
            stackView.addArrangedSubview(newContactCard)
        }
    }

    private func saveContacts() {
        UserDefaults.standard.set(contacts, forKey: "SavedContacts")
    }

    private func loadSavedContacts() {
        if let savedContacts = UserDefaults.standard.dictionary(forKey: "SavedContacts") as? [String: String] {
            contacts = savedContacts
        }
    }
}

extension EditContactViewController: CNContactViewControllerDelegate {
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        viewController.dismiss(animated: true, completion: nil)
        if let contact = contact {
            let fullName = [contact.givenName, contact.familyName].joined(separator: " ").trimmingCharacters(in: .whitespaces)
            let phoneNumber = contact.phoneNumbers.first?.value.stringValue ?? "Unknown"
            if !fullName.isEmpty {
                addNewContactCard(name: fullName, phoneNumber: phoneNumber)
            }
        }
    }
}
