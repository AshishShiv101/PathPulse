import UIKit
import ContactsUI
import FirebaseFirestore
import FirebaseAuth
import CoreLocation

class EditContactViewController: UIViewController, CNContactViewControllerDelegate, CLLocationManagerDelegate {
    private var contacts: [String: String] = [:]
    private let db = Firestore.firestore()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var contactsStackView = UIStackView()
    private var helplineStackView = UIStackView()
    private let personalButton = UIButton(type: .system)
    private let helplineButton = UIButton(type: .system)
    private let addButton = UIButton(type: .system)
    private let noContactsLabel: UILabel = {
        let label = UILabel()
        label.text = "Add Contacts\nor Long Press to Delete added contacts"
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private var isShowingPersonal = true
    private let locationManager = CLLocationManager()
    private let emergencyNumbersManager = EmergencyNumbersManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        setupScrollView()
        setupUI()
        loadContactsFromFirebase()
        setupNavigationBarAppearance()
        setupLocationManager()
        setupGestureRecognizers()
        
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
        configureSegmentButtons()
        configureAddButton()
        configureContactsStack()
        configureHelplineStack()
        contentView.addSubview(noContactsLabel)
        NSLayoutConstraint.activate([
            noContactsLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            noContactsLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 200)
        ])
        updateViewForCurrentSelection()
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
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }
    
    private func configureSegmentButtons() {
        personalButton.setTitle("Personal Contacts", for: .normal)
        personalButton.setTitleColor(.black, for: .normal)
        personalButton.backgroundColor = UIColor(hex: "#40CBD8")
        personalButton.layer.cornerRadius = 8
        personalButton.addTarget(self, action: #selector(switchToPersonal), for: .touchUpInside)
        personalButton.translatesAutoresizingMaskIntoConstraints = false
        
        helplineButton.setTitle("Helpline", for: .normal)
        helplineButton.setTitleColor(.white, for: .normal)
        helplineButton.backgroundColor = UIColor(hex: "#1E1E1E")
        helplineButton.layer.cornerRadius = 8
        helplineButton.addTarget(self, action: #selector(switchToHelpline), for: .touchUpInside)
        helplineButton.translatesAutoresizingMaskIntoConstraints = false
        
        let buttonStack = UIStackView(arrangedSubviews: [personalButton, helplineButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 10
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(buttonStack)
        
        NSLayoutConstraint.activate([
            buttonStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 60),
            buttonStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            buttonStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            buttonStack.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func configureAddButton() {
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        let image = UIImage(systemName: "plus", withConfiguration: config)
        addButton.setImage(image, for: .normal)
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
            contactsStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 120),
            contactsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contactsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            contactsStackView.bottomAnchor.constraint(greaterThanOrEqualTo: contentView.bottomAnchor, constant: -80)
        ])
        
        contentView.bottomAnchor.constraint(greaterThanOrEqualTo: contactsStackView.bottomAnchor, constant: 80).isActive = true
    }
    
    private func configureHelplineStack() {
        helplineStackView.axis = .vertical
        helplineStackView.spacing = 16
        helplineStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(helplineStackView)
        
        NSLayoutConstraint.activate([
            helplineStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 120),
            helplineStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            helplineStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            helplineStackView.bottomAnchor.constraint(greaterThanOrEqualTo: contentView.bottomAnchor, constant: -80)
        ])
        
        helplineStackView.isHidden = true
        updateHelplineNumbers()
    }
    
    @objc private func switchToPersonal() {
        isShowingPersonal = true
        personalButton.setTitleColor(.black, for: .normal)
        helplineButton.setTitleColor(.white, for: .normal)
        personalButton.backgroundColor = UIColor(hex: "#40CBD8")
        helplineButton.backgroundColor = UIColor(hex: "#1E1E1E")
        updateViewForCurrentSelection()
    }
    
    @objc private func switchToHelpline() {
        isShowingPersonal = false
        personalButton.setTitleColor(.white, for: .normal)
        helplineButton.setTitleColor(.black, for: .normal)
        personalButton.backgroundColor = UIColor(hex: "#1E1E1E")
        helplineButton.backgroundColor = UIColor(hex: "#40CBD8")
        updateViewForCurrentSelection()
    }
    
    private func updateViewForCurrentSelection() {
        if isShowingPersonal {
            contactsStackView.isHidden = false
            helplineStackView.isHidden = true
            noContactsLabel.isHidden = !contacts.isEmpty
            addButton.isHidden = false
            view.bringSubviewToFront(contactsStackView)
        } else {
            contactsStackView.isHidden = true
            helplineStackView.isHidden = false
            noContactsLabel.isHidden = true
            addButton.isHidden = true
            view.bringSubviewToFront(helplineStackView)
        }
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began && isShowingPersonal {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.prepare()
            impactFeedback.impactOccurred()

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
    
    private func createContactCard(title: String, phoneNumber: String, isHelpline: Bool = false) -> UIView {
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
        
        let buttonStack: UIStackView
        if isHelpline {
            buttonStack = UIStackView(arrangedSubviews: [callButton])
        } else {
            let messageButton = createActionButton(icon: "message.fill", action: #selector(sendMessage), phone: phoneNumber)
            buttonStack = UIStackView(arrangedSubviews: [callButton, messageButton])
            NSLayoutConstraint.activate([
                messageButton.widthAnchor.constraint(equalToConstant: 48),
                messageButton.heightAnchor.constraint(equalToConstant: 48)
            ])
        }
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
        
        if !isHelpline {
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            cardView.addGestureRecognizer(longPress)
            cardView.isUserInteractionEnabled = true
        }
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            mainStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
            
            callButton.widthAnchor.constraint(equalToConstant: 48),
            callButton.heightAnchor.constraint(equalToConstant: 48)
        ])
        
        return cardView
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
    
    @objc private func makeCall(_ sender: UIButton) {
        guard let phoneNumber = sender.accessibilityIdentifier,
              let url = URL(string: "tel://\(phoneNumber)") else {
            print("Failed to initiate call: Invalid phone number")
            return
        }
        
        print("Calling \(phoneNumber)")
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            print("Cannot make call: Device does not support calling or URL is invalid")
        }
    }
    
    @objc private func sendMessage(_ sender: UIButton) {
        guard let phoneNumber = sender.accessibilityIdentifier,
              let url = URL(string: "sms:\(phoneNumber)"),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
    
    private func loadContactsFromFirebase() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).collection("contacts")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error loading contacts: \(error)")
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
                    print("Error saving contact: \(error)")
                }
            }
    }
    
    private func deleteContactFromFirebase(name: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).collection("contacts").document(name)
            .delete { error in
                if let error = error {
                    print("Error deleting contact: \(error)")
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
            sortedContacts.forEach { (name, phone) in
                let card = createContactCard(title: name, phoneNumber: phone, isHelpline: false)
                contactsStackView.addArrangedSubview(card)
            }
        }
        
        view.layoutIfNeeded()
    }
    
    @objc private func addContactTapped() {
        if !isShowingPersonal { return }
        
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
    
    // MARK: - Location Management
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    private func setupGestureRecognizers() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        scrollView.keyboardDismissMode = .onDrag
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationManager.stopUpdatingLocation()
        
        emergencyNumbersManager.updateCountryCode(from: location) { [weak self] in
            self?.updateHelplineNumbers()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
        updateHelplineNumbers()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            updateHelplineNumbers()
            showLocationPermissionAlert()
        default:
            break
        }
    }
    
    private func showLocationPermissionAlert() {
        let alert = createDarkModeAlert(
            title: "Location Access Denied",
            message: "Please enable location services in Settings to get accurate emergency numbers for your area."
        )
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
        let okAction = UIAlertAction(title: "OK", style: .default)
        settingsAction.setValue(UIColor(hex: "#40CBD8"), forKey: "titleTextColor")
        okAction.setValue(UIColor(hex: "#40CBD8"), forKey: "titleTextColor")
        alert.addAction(settingsAction)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    private func updateHelplineNumbers() {
        helplineStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let numbers = emergencyNumbersManager.getEmergencyNumbers()
        for (title, number) in numbers {
            let card = createContactCard(title: title, phoneNumber: number, isHelpline: true)
            helplineStackView.addArrangedSubview(card)
        }
        
        updateViewForCurrentSelection()
    }
}

extension EditContactViewController: ManualEntryViewControllerDelegate {
    func didAddContact(name: String, phoneNumber: String) {
        processContact(name: name, phoneNumber: phoneNumber)
    }
    
    func didCancel() {
        // No action needed on cancel, just dismisses the view
    }
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


// ManualEntryViewController Implementation
protocol ManualEntryViewControllerDelegate: AnyObject {
    func didAddContact(name: String, phoneNumber: String)
    func didCancel()
}

class ManualEntryViewController: UIViewController {
    weak var delegate: ManualEntryViewControllerDelegate?
    
    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter name"
        textField.borderStyle = .roundedRect
        textField.backgroundColor = UIColor(hex: "#1E1E1E")
        textField.textColor = .white
        textField.attributedPlaceholder = NSAttributedString(
            string: "Enter name",
            attributes: [.foregroundColor: UIColor.lightGray]
        )
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let phoneTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter phone number"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .phonePad
        textField.backgroundColor = UIColor(hex: "#1E1E1E")
        textField.textColor = .white
        textField.attributedPlaceholder = NSAttributedString(
            string: "Enter phone number",
            attributes: [.foregroundColor: UIColor.lightGray]
        )
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(hex: "#40CBD8")
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(hex: "#FF5555")
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5) // Dimmed background
    }
    
    private func setupUI() {
        let containerView = UIView()
        containerView.backgroundColor = UIColor(hex: "#222222")
        containerView.layer.cornerRadius = 15
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        let stackView = UIStackView(arrangedSubviews: [nameTextField, phoneTextField])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let buttonStack = UIStackView(arrangedSubviews: [saveButton, cancelButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 20
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(stackView)
        containerView.addSubview(buttonStack)
        
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 300),
            containerView.heightAnchor.constraint(equalToConstant: 200),
            
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            buttonStack.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20),
            buttonStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            buttonStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            buttonStack.heightAnchor.constraint(equalToConstant: 40),
            buttonStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func saveTapped() {
        guard let name = nameTextField.text?.trimmingCharacters(in: .whitespaces), !name.isEmpty,
              let phoneNumber = phoneTextField.text?.trimmingCharacters(in: .whitespaces), !phoneNumber.isEmpty else {
            // Optionally, show an alert here if fields are empty
            return
        }
        
        delegate?.didAddContact(name: name, phoneNumber: phoneNumber)
        dismiss(animated: true)
    }
    
    @objc private func cancelTapped() {
        delegate?.didCancel()
        dismiss(animated: true)
    }
}

// Placeholder for CustomContactPickerViewController
class CustomContactPickerViewController: CNContactPickerViewController {}
