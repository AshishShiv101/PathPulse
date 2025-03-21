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
    
    // Add a closure for dismissal handling
    public var onDismiss: (() -> Void)?
    
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
        
        layer.zPosition = 1
        mainStackView.layer.zPosition = 2
        
        NSLayoutConstraint.activate([
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            mainStackView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
        
        NSLayoutConstraint.activate([
            contactsStackView.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor),
            contactsStackView.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor)
        ])
        
        // Make the view interactive to prevent taps from passing through
        isUserInteractionEnabled = true
    }
    
    // Override this method to add the background tap functionality when added to superview
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if let superview = superview {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap(_:)))
            superview.addGestureRecognizer(tapGesture)
        }
    }
    
    public func addContactIcon(iconName: String, label: String, number: String) {
        let contactIcon = createContactIcon(with: iconName, label: label, number: number)
        contactsStackView.addArrangedSubview(contactIcon)
        bringSubviewToFront(contactIcon)
    }
    
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
        button.accessibilityLabel = number
        
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
    
    @objc private func handleBackgroundTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        
        // Check if the tap is outside the overlay bounds
        if !self.bounds.contains(location) {
            onDismiss?()
        }
    }
}
