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
        
        // Dark Overlay on Image
        let darkOverlay = UIView()
        darkOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.4) // Darker effect
        darkOverlay.translatesAutoresizingMaskIntoConstraints = false
        imageView.addSubview(darkOverlay)  // Add the overlay on the image view
        
        // Title Label - Positioned below the image, above the description
        let titleLabel = UILabel()
        titleLabel.text = selectedItem.title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 32)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.layer.shadowColor = UIColor.black.cgColor
        titleLabel.layer.shadowOpacity = 0.3
        titleLabel.layer.shadowOffset = CGSize(width: 2, height: 2)
        view.addSubview(titleLabel)  // Add the title label directly to the view
        
        // Description Label - Positioned below the title
        let descriptionLabel = UILabel()
        descriptionLabel.text = selectedItem.description
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textColor = .white
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        descriptionLabel.layer.cornerRadius = 10
        descriptionLabel.layer.masksToBounds = true
        descriptionLabel.setPadding(8)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descriptionLabel)
        
        // Location Button with Icon
        let locationButton = UIButton(type: .system)
        locationButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
        styleButton(locationButton)
        
        // Call Button with Icon
        let callButton = UIButton(type: .system)
        callButton.setImage(UIImage(systemName: "phone.fill"), for: .normal)
        styleButton(callButton)
        
        // Add Subviews
        view.addSubview(locationButton)
        view.addSubview(callButton)
        
        // Layout Constraints
        NSLayoutConstraint.activate([
            // Image View Constraints (Covering the top half of the screen)
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5), // Take half of the screen height
            
            // Dark Overlay Constraints (Covering the entire image)
            darkOverlay.topAnchor.constraint(equalTo: imageView.topAnchor),
            darkOverlay.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            darkOverlay.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            darkOverlay.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            
            // Title Label Constraints (Positioned below the image, above the description)
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Description Label Constraints (Positioned below the title)
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            descriptionLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
            
            // Location Button Constraints
            locationButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 100),
            locationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            locationButton.widthAnchor.constraint(equalToConstant: 50),
            locationButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Call Button Constraints
            callButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -100),
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
        button.layer.shadowOffset = CGSize(width: 2, height: 2)
        button.translatesAutoresizingMaskIntoConstraints = false
    }
}

extension UILabel {
    func setPadding(_ padding: CGFloat) {
        self.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        let paddingLayer = CALayer()
        paddingLayer.frame = bounds.insetBy(dx: -padding, dy: -padding)
        paddingLayer.backgroundColor = UIColor.clear.cgColor
        layer.insertSublayer(paddingLayer, at: 0)
    }
}
