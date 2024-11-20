import UIKit

class SOSOverlayView: UIView {

    private let mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let contactsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 24
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let addContactBox: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#444444")
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let addContactLabel: UILabel = {
        let label = UILabel()
        label.text = "Add Contact"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let appleIconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "person.crop.circle.badge.plus"))
        imageView.tintColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = UIColor.black.withAlphaComponent(0.85)
        layer.cornerRadius = 16
        clipsToBounds = true

        addSubview(mainStackView)
        mainStackView.addArrangedSubview(contactsStackView)
        
        // Add the Add Contact box between the emergency contacts and the other buttons
        mainStackView.addArrangedSubview(addContactBox)

        addContactBox.addSubview(addContactLabel)
        addContactBox.addSubview(appleIconImageView)

        // Set zPosition for proper layering
        layer.zPosition = 1
        mainStackView.layer.zPosition = 2
        addContactBox.layer.zPosition = 3

        // Adjust constraints for mainStackView
        NSLayoutConstraint.activate([
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            mainStackView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16) // Ensure space at the bottom
        ])
        
        // Set height constraints for the addContactBox
        NSLayoutConstraint.activate([
            addContactBox.heightAnchor.constraint(equalToConstant: 50),
            
            addContactLabel.centerYAnchor.constraint(equalTo: addContactBox.centerYAnchor),
            addContactLabel.leadingAnchor.constraint(equalTo: addContactBox.leadingAnchor, constant: 16),
            
            appleIconImageView.centerYAnchor.constraint(equalTo: addContactBox.centerYAnchor),
            appleIconImageView.leadingAnchor.constraint(equalTo: addContactLabel.trailingAnchor, constant: 8),
            appleIconImageView.trailingAnchor.constraint(equalTo: addContactBox.trailingAnchor, constant: -16),
            appleIconImageView.widthAnchor.constraint(equalToConstant: 24),
            appleIconImageView.heightAnchor.constraint(equalToConstant: 24)
        ])

        // Adjust the contactsStackView's constraints so it can expand and not get clipped
        NSLayoutConstraint.activate([
            contactsStackView.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor),
            contactsStackView.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor)
        ])
    }

    // Ensure contacts are properly layered
    public func addContactIcon(iconName: String, label: String, number: String) {
        let contactIcon = createContactIcon(with: iconName, label: label, number: number)
        contactsStackView.addArrangedSubview(contactIcon)
        bringSubviewToFront(contactIcon)
    }

    // Adjust zPosition for dynamically added views
    private func createContactIcon(with systemImageName: String, label: String, number: String) -> UIView {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: systemImageName), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor(hex: "#333333")
        button.layer.cornerRadius = 25
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.imageView?.contentMode = .scaleAspectFit
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(contactTapped(_:)), for: .touchUpInside)
        button.accessibilityLabel = number // Store the number in the button for later use

        // Ensure button zPosition
        button.layer.zPosition = 4

        let labelView = UILabel()
        labelView.text = label
        labelView.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        labelView.textColor = .white
        labelView.textAlignment = .center
        labelView.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView(arrangedSubviews: [button, labelView])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 50),
            button.widthAnchor.constraint(equalToConstant: 50)
        ])
        
        return stackView
    }


    @objc private func contactTapped(_ sender: UIButton) {
        guard let number = sender.accessibilityLabel,
              !number.isEmpty,
              let url = URL(string: "tel://\(number)") else {
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

}
