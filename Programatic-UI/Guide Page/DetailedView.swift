import UIKit
import MapKit

class DetailedView: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private let selectedItem: GuideItem
    private var imageCollectionView: UICollectionView!
    private var images: [UIImage] = []
    
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
        fetchImages()
    }

    private func configureView() {
        view.backgroundColor = UIColor(hex: "#222222")
        setupLayout()
        
        view.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.view.alpha = 1
        }
    }
    
    private func setupLayout() {
        imageCollectionView = createImageCollectionView()
        view.addSubview(imageCollectionView)
        
        let titleLabel = createTitleLabel(with: selectedItem.title)
        view.addSubview(titleLabel)
        
        let infoContainer = createInfoContainer()
        let infoStackView = createInfoStackView()
        
        infoStackView.addArrangedSubview(createInfoLabel(title: "Location", value: selectedItem.location))
        infoStackView.addArrangedSubview(createInfoLabel(title: "Rating", value: String(format: "%.1f ★", selectedItem.rating)))
        
        if let price = selectedItem.price {
            infoStackView.addArrangedSubview(createInfoLabel(title: "Average Price", value: String(format: "$%.2f", price)))
        }
        
        infoContainer.addSubview(infoStackView)
        view.addSubview(infoContainer)
        
        let buttonStack = createButtonStack()
        buttonStack.addArrangedSubview(createActionButton(imageName: "location.fill", action: #selector(handleLocationTapped)))
        buttonStack.addArrangedSubview(createActionButton(imageName: "square.and.arrow.up", action: #selector(handleShareTapped)))
        buttonStack.addArrangedSubview(createActionButton(imageName: "phone.fill", action: #selector(handleCallTapped)))
        view.addSubview(buttonStack)
        
        NSLayoutConstraint.activate([
            imageCollectionView.topAnchor.constraint(equalTo: view.topAnchor),
            imageCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageCollectionView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.45),
            
            titleLabel.topAnchor.constraint(equalTo: imageCollectionView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            infoContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            infoContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            infoStackView.topAnchor.constraint(equalTo: infoContainer.topAnchor, constant: 20),
            infoStackView.leadingAnchor.constraint(equalTo: infoContainer.leadingAnchor, constant: 20),
            infoStackView.trailingAnchor.constraint(equalTo: infoContainer.trailingAnchor, constant: -20),
            infoStackView.bottomAnchor.constraint(equalTo: infoContainer.bottomAnchor, constant: -20),
            
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            buttonStack.heightAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    private func createImageCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        return collectionView
    }
    
    private func fetchImages() {
        // Assuming imageName is optional, we'll safely unwrap it and handle multiple images
        var imageURLs: [String] = []
        
        // Add the primary image if it exists
        if let primaryImage = selectedItem.imageName {
            imageURLs.append(primaryImage)
        }
        
        // Add additional placeholder URLs (replace with actual URLs from your data source)
        imageURLs.append(contentsOf: [
            "https://example.com/image2.jpg",
            "https://example.com/image3.jpg"
        ])
        
        for urlString in imageURLs {
            // urlString is now guaranteed to be non-optional String
            if let imageUrl = URL(string: urlString) {
                URLSession.shared.dataTask(with: imageUrl) { [weak self] data, _, error in
                    guard let data = data, error == nil, let image = UIImage(data: data) else { return }
                    DispatchQueue.main.async {
                        self?.images.append(image)
                        self?.imageCollectionView.reloadData()
                    }
                }.resume()
            }
        }
    }
    
    // UICollectionView Methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count > 0 ? images.count : 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
        if !images.isEmpty {
            cell.configure(with: images[indexPath.item])
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.bounds.width, height: view.bounds.height * 0.45)
    }
    
    private func createTitleLabel(with text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 34, weight: .heavy)
        label.textColor = .white
        label.textAlignment = .left
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOpacity = 0.2
        label.layer.shadowOffset = CGSize(width: 0, height: 2)
        label.layer.shadowRadius = 4
        return label
    }
    
    private func createInfoContainer() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#333333")
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 8
        return view
    }
    
    private func createInfoStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }
    
    private func createInfoLabel(title: String, value: String) -> UILabel {
        let label = UILabel()
        let attributedText = NSMutableAttributedString(
            string: "\(title): ",
            attributes: [.foregroundColor: UIColor(hex: "#40CBD8")]
        )
        attributedText.append(NSAttributedString(
            string: value,
            attributes: [.foregroundColor: UIColor.white]
        ))

        if title == "Rating" {
            let starRange = (value as NSString).range(of: "★")
            if starRange.location != NSNotFound {
                attributedText.addAttribute(.foregroundColor,
                                            value: UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0),
                                            range: starRange)
            }
        }

        label.attributedText = attributedText
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.9)
        label.numberOfLines = 0
        return label
    }
   private func createButtonStack() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }
    
    private func createActionButton(imageName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        let configuration = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        button.setImage(UIImage(systemName: imageName, withConfiguration: configuration)?.withTintColor(.white), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor(hex: "#40CBD8")
        button.layer.cornerRadius = 35
        
        button.layer.shadowColor = UIColor(hex: "#40CBD8").cgColor
        button.layer.shadowOpacity = 0.4
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 70).isActive = true
        button.widthAnchor.constraint(equalToConstant: 70).isActive = true
        
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonReleased(_:)), for: [.touchUpInside, .touchUpOutside])
        return button
    }
    
    @objc private func buttonTapped(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc private func buttonReleased(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = .identity
        }
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
    
    private func fetchPhoneNumberFromAPI(completion: @escaping (String?) -> Void) {
        let baseUrl = "https://maps.googleapis.com/maps/api/place/details/json"
        let apiKey = "AIzaSyAkRf97JQAwepJSR6coaCQBQ5WpsOWLNyE"
        let placeId = selectedItem.placeId
        let urlString = "\(baseUrl)?place_id=\(placeId)&fields=formatted_phone_number&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { completion(nil) }
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil,
                  let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            do {
                let response = try JSONDecoder().decode(PlaceDetailsResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(response.result.formatted_phone_number)
                }
            } catch {
                DispatchQueue.main.async { completion(nil) }
            }
        }.resume()
    }

    struct PlaceDetailsResponse: Codable {
        let result: PlaceDetailResult
        struct PlaceDetailResult: Codable {
            let formatted_phone_number: String?
        }
    }

    @objc private func handleCallTapped() {
        fetchPhoneNumberFromAPI { [weak self] phoneNumber in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let number = phoneNumber {
                    let cleanedNumber = number.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
                    if let phoneURL = URL(string: "tel://\(cleanedNumber)"),
                       UIApplication.shared.canOpenURL(phoneURL) {
                        UIApplication.shared.open(phoneURL, options: [:]) { success in
                            if !success {
                                self.showAlert(message: "Failed to initiate call")
                            }
                        }
                    } else {
                        self.showAlert(message: "Unable to make calls on this device")
                    }
                } else {
                    self.showAlert(message: "Phone number not available")
                }
            }
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Info", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        alert.view.tintColor = UIColor(hex: "#40CBD8")
        present(alert, animated: true)
    }
}

class ImageCell: UICollectionViewCell {
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 16
        iv.translatesAutoresizingMaskIntoConstraints = false
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.7).cgColor]
        gradientLayer.locations = [0.4, 1.0]
        iv.layer.addSublayer(gradientLayer)
        
        iv.layer.shadowColor = UIColor.black.cgColor
        iv.layer.shadowOpacity = 0.3
        iv.layer.shadowOffset = CGSize(width: 0, height: 4)
        iv.layer.shadowRadius = 8
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.layer.sublayers?.first?.frame = bounds
    }
    
    func configure(with image: UIImage) {
        imageView.image = image
    }
}
