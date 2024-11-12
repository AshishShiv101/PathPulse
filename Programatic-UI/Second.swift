import UIKit

class Second: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#222222")
        let logoImageView = AppLogoView()
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoImageView)
        let cardStack = UIStackView(arrangedSubviews: [
            CardView(imageName: "Clouds", text: "Why worry about the weather when we can do it on your behalf.", isImageAsset: true),
            CardView(imageName: "News", text: "Unsure about your plans? Don’t worry, we’ve got that covered as well.", isImageAsset: true),
            CardView(imageName: "Hotels", text: "Uncertain about the plans you’ve made? We’ve got you covered there too.", isImageAsset: true)
        ])
        cardStack.axis = .vertical
        cardStack.spacing = 40
        cardStack.layoutMargins = UIEdgeInsets(top: 90, left: 16, bottom: 0, right: 16)
        cardStack.isLayoutMarginsRelativeArrangement = true
        
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardStack)
        let getStartedButton = UIButton(type: .system)
        getStartedButton.setTitle("Get Started", for: .normal)
        getStartedButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        getStartedButton.setTitleColor(.white, for: .normal)
        getStartedButton.backgroundColor = UIColor(hex: "40CBD8")
        getStartedButton.layer.cornerRadius = 10
        getStartedButton.translatesAutoresizingMaskIntoConstraints = false
        getStartedButton.addTarget(self, action: #selector(MapNav), for: .touchUpInside)
        view.addSubview(getStartedButton)
        NSLayoutConstraint.activate([
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardStack.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 30),
            cardStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cardStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            getStartedButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            getStartedButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            getStartedButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            getStartedButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    @objc private func MapNav() {
        let thirdViewController = LoginPage()
        navigationController?.pushViewController(thirdViewController, animated: true)
    }
}

// Reusable CardView for each information card
class CardView: UIView {
    
    init(imageName: String, text: String, isImageAsset: Bool) {
        super.init(frame: .zero)
        setupView(imageName: imageName, text: text, isImageAsset: isImageAsset)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView(imageName: String, text: String, isImageAsset: Bool) {
        backgroundColor = UIColor.black.withAlphaComponent(0.3)
        layer.cornerRadius = 12
        translatesAutoresizingMaskIntoConstraints = false
        
        let imageView: UIImageView
        if isImageAsset {
            imageView = UIImageView(image: UIImage(named: imageName))
        } else {
            imageView = UIImageView(image: UIImage(systemName: imageName))
        }
        imageView.tintColor = UIColor(hex: "40CBD8")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let textLabel = UILabel()
        textLabel.text = text
        textLabel.textColor = .white
        textLabel.font = UIFont.systemFont(ofSize: 16)
        textLabel.numberOfLines = 0
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView(arrangedSubviews: [imageView, textLabel])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 25
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        // Constraints
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
}

// App Logo UIView (Placeholder)
class AppLogoView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLogo()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLogo() {
        // Set up your app logo here
        let pathLabel = UILabel()
        pathLabel.text = "Path"
        pathLabel.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        pathLabel.textColor = UIColor(hex: "40CBD8")
        pathLabel.translatesAutoresizingMaskIntoConstraints = false

        let pulseLabel = UILabel()
        pulseLabel.text = "Pulse"
        pulseLabel.font = UIFont.systemFont(ofSize: 40, weight: .regular)
        pulseLabel.textColor = .white
        pulseLabel.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView(arrangedSubviews: [pathLabel, pulseLabel])
        stackView.axis = .horizontal
        stackView.spacing = 5
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let roadImageView = UIImageView(image: UIImage(systemName: "road.lanes.curved.right"))
       
        roadImageView.tintColor = UIColor(hex: "40CBD8")
        roadImageView.contentMode = .scaleAspectFit
        roadImageView.translatesAutoresizingMaskIntoConstraints = false

        // Add both stackView and roadImageView to the view
        addSubview(stackView)
        addSubview(roadImageView)

        // Constraints
        NSLayoutConstraint.activate([
            // Center stackView horizontally and vertically
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            // Position roadImageView below stackView
            roadImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            // Position roadImageView below stackView with reduced top margin
            roadImageView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 1), // Reduced margin from 10 to 5

            roadImageView.widthAnchor.constraint(equalToConstant: 80),
            roadImageView.heightAnchor.constraint(equalToConstant: 50)
        ])


    }
}

// Utility extension to handle hex colors
extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.hasPrefix("#") ? String(hexSanitized.dropFirst()) : hexSanitized

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
