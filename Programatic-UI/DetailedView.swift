import UIKit

class DetailedView: UIViewController {
    
    var selectedItem: GuideItem
    init(selectedItem: GuideItem) {
        self.selectedItem = selectedItem
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        view.backgroundColor = UIColor(hex: "#222222") // Assuming UIColor extension exists
    }
    
    private func setupUI() {
        // Image View - Covering half of the screen
        let imageView = UIImageView()
        imageView.image = UIImage(named: selectedItem.imageName)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 12
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        // Gradient Overlay on Image
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.6).cgColor]
        gradientLayer.locations = [0.5, 1.0]
        gradientLayer.frame = imageView.bounds
        imageView.layer.addSublayer(gradientLayer)
        
        // Title Label - Positioned below the image, above the additional info
        let titleLabel = UILabel()
        titleLabel.text = selectedItem.title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 36)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.layer.shadowColor = UIColor.black.cgColor
        titleLabel.layer.shadowOpacity = 0.3
        titleLabel.layer.shadowOffset = CGSize(width: 2, height: 2)
        titleLabel.numberOfLines = 2
        view.addSubview(titleLabel)
        
        // Box Container for Info
        let infoContainer = UIView()
        infoContainer.backgroundColor = UIColor(hex: "#333333")
        infoContainer.layer.cornerRadius = 12
        infoContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(infoContainer)
        
        // Address, Phone, and Hours Stack View
        let infoStackView = UIStackView()
        infoStackView.axis = .vertical
        infoStackView.alignment = .leading
        infoStackView.spacing = 12
        infoStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Address Label
        let addressLabel = UILabel()
        addressLabel.text = "Address: \(selectedItem.address)"
        addressLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        addressLabel.textColor = .white
        addressLabel.numberOfLines = 0
        infoStackView.addArrangedSubview(addressLabel)
        
        // Phone Label
        let phoneLabel = UILabel()
        phoneLabel.text = "Phone: \(selectedItem.phone)"
        phoneLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        phoneLabel.textColor = .white
        phoneLabel.numberOfLines = 0
        infoStackView.addArrangedSubview(phoneLabel)
        
        // Hours Label
        let hoursLabel = UILabel()
        hoursLabel.text = "Hours: \(selectedItem.hours)"
        hoursLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        hoursLabel.textColor = .white
        hoursLabel.numberOfLines = 0
        infoStackView.addArrangedSubview(hoursLabel)
        
        // Add info stack view to container view
        infoContainer.addSubview(infoStackView)
        
        // Location Button with Icon
        let locationButton = UIButton(type: .system)
        locationButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
        styleButton(locationButton)
        
        // Call Button with Icon
        let callButton = UIButton(type: .system)
        callButton.setImage(UIImage(systemName: "phone.fill"), for: .normal)
        styleButton(callButton)
        
        // Share Button with Icon
        let shareButton = UIButton(type: .system)
        shareButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        styleButton(shareButton)
        
        // Add Subviews
        view.addSubview(locationButton)
        view.addSubview(callButton)
        view.addSubview(shareButton)
        
        // Layout Constraints
        NSLayoutConstraint.activate([
            // Image View Constraints
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),
            
            // Title Label Constraints
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Info Container Constraints
            infoContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            infoContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Info Stack View Constraints (within the container)
            infoStackView.topAnchor.constraint(equalTo: infoContainer.topAnchor, constant: 20),
            infoStackView.leadingAnchor.constraint(equalTo: infoContainer.leadingAnchor, constant: 20),
            infoStackView.trailingAnchor.constraint(equalTo: infoContainer.trailingAnchor, constant: -20),
            infoStackView.bottomAnchor.constraint(equalTo: infoContainer.bottomAnchor, constant: -20),
            
            // Location Button Constraints
            locationButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            locationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            locationButton.widthAnchor.constraint(equalToConstant: 50),
            locationButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Share Button Constraints
            shareButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shareButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            shareButton.widthAnchor.constraint(equalToConstant: 50),
            shareButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Call Button Constraints
            callButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            callButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            callButton.widthAnchor.constraint(equalToConstant: 50),
            callButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }

    private func styleButton(_ button: UIButton) {
        button.tintColor = .white
        button.backgroundColor = UIColor(hex: "40CBD8")
        button.layer.cornerRadius = 25
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 3, height: 3)
        button.layer.shadowRadius = 5
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
    }
}
