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
        // Title Label
        let titleLabel = UILabel()
        titleLabel.text = selectedItem.title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 32)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Image View
        let imageView = UIImageView()
        imageView.image = UIImage(named: selectedItem.imageName)
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        // Description Label
        let descriptionLabel = UILabel()
        descriptionLabel.text = selectedItem.description
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textColor = .white
        descriptionLabel.numberOfLines = 0
        descriptionLabel.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        descriptionLabel.layer.cornerRadius = 10
        descriptionLabel.layer.masksToBounds = true
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descriptionLabel)
        
        // Location Button
        let locationButton = UIButton(type: .system)
        locationButton.setTitle("Location", for: .normal)
        locationButton.setTitleColor(.white, for: .normal)
        locationButton.backgroundColor = UIColor(hex: "40CBD8")
        locationButton.layer.cornerRadius = 10
        locationButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(locationButton)
        
        // Call Button
        let callButton = UIButton(type: .system)
        callButton.setTitle("Call", for: .normal)
        callButton.setTitleColor(.white, for: .normal)
        callButton.backgroundColor = UIColor(hex: "40CBD8")
        callButton.layer.cornerRadius = 10
        callButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(callButton)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Title Label Constraints
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Image View Constraints
            imageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalToConstant: 200),
            
            // Description Label Constraints
            descriptionLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            descriptionLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
            
            // Location Button Constraints
            locationButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
            locationButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            locationButton.widthAnchor.constraint(equalToConstant: 150),
            locationButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Call Button Constraints
            callButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
            callButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            callButton.widthAnchor.constraint(equalToConstant: 150),
            callButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
}

let guideItem = GuideItem(title: "SRM", imageName: "Hospital1", description: "It provides various medical services and is known for its excellent healthcare.")
let detailedView = DetailedView(selectedItem: guideItem)
