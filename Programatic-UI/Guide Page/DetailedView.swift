import UIKit
import MapKit

class DetailedView: UIViewController {
    
    private let selectedItem: GuideItem
    
    init(selectedItem: GuideItem) {
        self.selectedItem = selectedItem
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    private func configureView() {
        view.backgroundColor = UIColor(hex: "#222222")
        setupLayout()
    }
    
    private func setupLayout() {
            let imageView = createImageView(with: selectedItem.imageName)
            view.addSubview(imageView)
            
            let titleLabel = createTitleLabel(with: selectedItem.title)
            view.addSubview(titleLabel)
            
            let infoContainer = createInfoContainer()
            let infoStackView = createInfoStackView()
            
            infoStackView.addArrangedSubview(createInfoLabel(title: "Hours", value: selectedItem.hours))
            infoStackView.addArrangedSubview(createInfoLabel(title: "Location", value: selectedItem.location))
            infoStackView.addArrangedSubview(createInfoLabel(title: "Rating", value: String(selectedItem.rating)))
            
            if let price = selectedItem.price {
                infoStackView.addArrangedSubview(createInfoLabel(title: "Average Price", value: "\(price) USD"))
            }
            
            infoContainer.addSubview(infoStackView)
            view.addSubview(infoContainer)
            
            let buttonStack = createButtonStack()
            buttonStack.addArrangedSubview(createActionButton(imageName: "location.fill", action: #selector(handleLocationTapped)))
            buttonStack.addArrangedSubview(createActionButton(imageName: "square.and.arrow.up", action: #selector(handleShareTapped)))
            buttonStack.addArrangedSubview(createActionButton(imageName: "phone.fill", action: #selector(handleCallTapped)))
            view.addSubview(buttonStack)
            
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: view.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4),
                
                titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
                titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                
                infoContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
                infoContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                infoContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                
                infoStackView.topAnchor.constraint(equalTo: infoContainer.topAnchor, constant: 16),
                infoStackView.leadingAnchor.constraint(equalTo: infoContainer.leadingAnchor, constant: 16),
                infoStackView.trailingAnchor.constraint(equalTo: infoContainer.trailingAnchor, constant: -16),
                infoStackView.bottomAnchor.constraint(equalTo: infoContainer.bottomAnchor, constant: -16),
                
                buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
                buttonStack.heightAnchor.constraint(equalToConstant: 60)
            ])
        }
    
    private func createImageView(with imageName: String) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        if let imageUrl = URL(string: imageName) {
            URLSession.shared.dataTask(with: imageUrl) { data, response, error in
                guard let data = data, error == nil, let downloadedImage = UIImage(data: data) else {
                    print("Failed to download image: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                DispatchQueue.main.async {
                    imageView.image = downloadedImage
                }
            }.resume()
        }
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.6).cgColor]
        gradientLayer.locations = [0.5, 1.0]
        gradientLayer.frame = imageView.bounds
        imageView.layer.addSublayer(gradientLayer)
        
        return imageView
    }
    
    private func createTitleLabel(with text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.boldSystemFont(ofSize: 32)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func createInfoContainer() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#333333")
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
    
    private func createInfoStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }
    
    private func createInfoLabel(title: String, value: String) -> UILabel {
        let label = UILabel()
        label.text = "\(title): \(value)"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }
    
    private func createButtonStack() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }
    
    private func createActionButton(imageName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: imageName), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor(hex: "#40CBD8")
        button.layer.cornerRadius = 30
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        button.widthAnchor.constraint(equalToConstant: 60).isActive = true
        return button
    }
    
    @objc private func handleLocationTapped() {
        let mapPage = MapPage()
        mapPage.destinationAddress = selectedItem.location
        mapPage.destinationName = selectedItem.title
        mapPage.tabBarItem = UITabBarItem(title: "Map", image: UIImage(systemName: "map.fill"), tag: 0)
        
        let guidePage = GuidePage()
        guidePage.tabBarItem = UITabBarItem(title: "Guide", image: UIImage(systemName: "bookmark.fill"), tag: 1)
        let guideNavigationController = UINavigationController(rootViewController: guidePage)
        
        let accountPage = AccountPage()
        accountPage.tabBarItem = UITabBarItem(title: "Account", image: UIImage(systemName: "person.crop.circle"), tag: 2)
        let accNav = UINavigationController(rootViewController: accountPage)
        
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [mapPage, guideNavigationController, accNav]
        
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(hex: "#333333")
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(hex: "#40cbd8")
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(hex: "#40cbd8")]
            appearance.stackedLayoutAppearance.normal.iconColor = .white
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            tabBarController.tabBar.standardAppearance = appearance
            tabBarController.tabBar.scrollEdgeAppearance = appearance
        } else {
            tabBarController.tabBar.barTintColor = UIColor(hex: "#333333")
            tabBarController.tabBar.tintColor = UIColor(hex: "#40cbd8")
            tabBarController.tabBar.unselectedItemTintColor = .white
        }
        
        tabBarController.modalPresentationStyle = .fullScreen
        present(tabBarController, animated: true) {
            mapPage.navigateToAddress(self.selectedItem.location, name: self.selectedItem.title)
        }
    }


        @objc private func handleShareTapped() {
            let encodedLocation = selectedItem.location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let googleMapsURL = "https://www.google.com/maps/search/?api=1&query=\(encodedLocation)"
            let activityViewController = UIActivityViewController(activityItems: [googleMapsURL], applicationActivities: nil)
            present(activityViewController, animated: true)
        }
        
        @objc private func handleCallTapped() {
            guard let phoneNumber = selectedItem.phoneNumber else {
                print("Phone number not available")
                return
            }
            
            if let phoneURL = URL(string: "tel://\(phoneNumber)") {
                if UIApplication.shared.canOpenURL(phoneURL) {
                    UIApplication.shared.open(phoneURL)
                } else {
                    print("Unable to make a call")
                }
            }
        }
    
}
