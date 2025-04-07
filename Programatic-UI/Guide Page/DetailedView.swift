import UIKit
import MapKit
import CoreLocation

class DetailedView: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, MKMapViewDelegate, CLLocationManagerDelegate {
    
    private let selectedItem: GuideItem
    private var imageCollectionView: UICollectionView!
    private var images: [UIImage] = []
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private let locationManager = CLLocationManager()
    
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
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    private func configureView() {
        view.backgroundColor = UIColor(hex: "#222222")
        setupScrollView()
        setupLayout()
        
        view.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.view.alpha = 1
        }
    }
    
    private func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupLayout() {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let imageHeightMultiplier: CGFloat = isPad ? 0.6 : 0.45
        let buttonSize: CGFloat = isPad ? 90 : 70
        
        imageCollectionView = createImageCollectionView()
        contentView.addSubview(imageCollectionView)
        
        let titleLabel = createTitleLabel(with: selectedItem.title)
        contentView.addSubview(titleLabel)
        
        let infoContainer = createInfoContainer()
        let infoStackView = createInfoStackView()
        
        infoStackView.addArrangedSubview(createInfoLabel(title: "Location", value: selectedItem.location))
        
        let ratingText: String
        if let userRatingsTotal = selectedItem.userRatingsTotal {
            ratingText = String(format: "%.1f ★ (%d reviews)", selectedItem.rating, userRatingsTotal)
        } else {
            ratingText = String(format: "%.1f ★", selectedItem.rating)
        }
        infoStackView.addArrangedSubview(createInfoLabel(title: "Rating", value: ratingText))
        
        if let price = selectedItem.price {
            infoStackView.addArrangedSubview(createInfoLabel(title: "Average Price", value: String(format: "$%.2f", price)))
        }
        
        infoContainer.addSubview(infoStackView)
        contentView.addSubview(infoContainer)
        
        let buttonStack = createButtonStack()
        buttonStack.addArrangedSubview(createActionButton(imageName: "location.fill", action: #selector(handleLocationTapped)))
        buttonStack.addArrangedSubview(createActionButton(imageName: "square.and.arrow.up", action: #selector(handleShareTapped)))
        buttonStack.addArrangedSubview(createActionButton(imageName: "phone.fill", action: #selector(handleCallTapped)))
        contentView.addSubview(buttonStack)
        
        NSLayoutConstraint.activate([
            imageCollectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageCollectionView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: imageHeightMultiplier),
            
            titleLabel.topAnchor.constraint(equalTo: imageCollectionView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            infoContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            infoContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            infoContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            infoStackView.topAnchor.constraint(equalTo: infoContainer.topAnchor, constant: 20),
            infoStackView.leadingAnchor.constraint(equalTo: infoContainer.leadingAnchor, constant: 20),
            infoStackView.trailingAnchor.constraint(equalTo: infoContainer.trailingAnchor, constant: -20),
            infoStackView.bottomAnchor.constraint(equalTo: infoContainer.bottomAnchor, constant: -20),
            
            buttonStack.topAnchor.constraint(equalTo: infoContainer.bottomAnchor, constant: 30),
            buttonStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            buttonStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            buttonStack.heightAnchor.constraint(equalToConstant: buttonSize),
            
            contentView.bottomAnchor.constraint(greaterThanOrEqualTo: buttonStack.bottomAnchor, constant: 30)
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
        var imageURLs: [String] = []
        if let primaryImage = selectedItem.imageName {
            imageURLs.append(primaryImage)
        }
        imageURLs.append(contentsOf: [
            "https://example.com/image2.jpg",
            "https://example.com/image3.jpg"
        ])
        
        for urlString in imageURLs {
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
        stackView.spacing = 16
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
        
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let size: CGFloat = isPad ? 90 : 70
        button.heightAnchor.constraint(equalToConstant: size).isActive = true
        button.widthAnchor.constraint(equalToConstant: size).isActive = true
        
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
        if let userLocation = locationManager.location?.coordinate {
            let bottomSheetVC = BottomSheetViewController(sourceCoordinate: userLocation, destinationAddress: selectedItem.location)
            bottomSheetVC.modalPresentationStyle = .overFullScreen
            present(bottomSheetVC, animated: false)
        } else {
            print("User location not available")
        }
    }
    
    @objc private func handleShareTapped() {
        let encodedLocation = selectedItem.location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let googleMapsURL = "https://www.google.com/maps/search/?api=1&query=\(encodedLocation)"
        let activityViewController = UIActivityViewController(activityItems: [googleMapsURL], applicationActivities: nil)
        
        // Add iPad support
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX,
                                                y: view.bounds.midY,
                                                width: 0,
                                                height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(activityViewController, animated: true)
    }
    private func fetchPhoneNumberFromAPI(completion: @escaping (String?) -> Void) {
        let baseUrl = "https://maps.googleapis.com/maps/api/place/details/json"
        let apiKey = "AIzaSyC80tpuSb7UN9YtmWhx-4qTITNdL2sgkTQ"
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
                    print("Phone number: \(number)")
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
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // No longer needed for bottom sheet since it's handled by BottomSheetViewController
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
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
