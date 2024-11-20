import UIKit
import ContactsUI

class EditContactViewController: UIViewController {
    private var contactNames: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "darkBackground") ?? UIColor(hex: "#222222")
        
        loadSavedContacts()
        setupUI()
    }

    private func setupUI() {
        let titleLabel = UILabel()
        titleLabel.text = "Edit Contact"
        titleLabel.font = UIFont.systemFont(ofSize: 26, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        for name in contactNames {
            let contactCard = createContactCard(title: name)
            stackView.addArrangedSubview(contactCard)
        }

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
    private func createContactCard(title: String) -> UIView {
        let cardView = UIView()
        cardView.backgroundColor = UIColor(named: "inputBackground") ?? UIColor.darkGray
        cardView.layer.cornerRadius = 12
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.heightAnchor.constraint(equalToConstant: 80).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let addButton = UIButton(type: .system)
        addButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addButton.tintColor = UIColor(named: "buttonColor") ?? UIColor(hex: "#40cbd8")
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)

        cardView.addSubview(titleLabel)
        cardView.addSubview(addButton)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),

            addButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            addButton.centerYAnchor.constraint(equalTo: cardView.centerYAnchor)
        ])

        return cardView
    }
    @objc private func addButtonTapped() {
        print("Add button tapped!")
    }


    private func addNewContactCard(name: String) {
        contactNames.append(name)
        saveContacts()
        if let stackView = view.subviews.first(where: { $0 is UIStackView }) as? UIStackView {
            let newContactCard = createContactCard(title: name)
            stackView.addArrangedSubview(newContactCard)
        }
    }

    @objc private func addContactTapped() {
        let contactViewController = CNContactViewController(forNewContact: nil)
        contactViewController.delegate = self
        let navigationController = UINavigationController(rootViewController: contactViewController)
        present(navigationController, animated: true, completion: nil)
    }

    private func saveContacts() {
        UserDefaults.standard.set(contactNames, forKey: "SavedContacts")
    }

    private func loadSavedContacts() {
        if let savedContacts = UserDefaults.standard.array(forKey: "SavedContacts") as? [String] {
            contactNames = savedContacts
        }
    }
}

extension EditContactViewController: CNContactViewControllerDelegate {
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        viewController.dismiss(animated: true, completion: nil)
        if let contact = contact {
            let fullName = [contact.givenName, contact.familyName].joined(separator: " ").trimmingCharacters(in: .whitespaces)
            addNewContactCard(name: fullName)
        }
    }
}
