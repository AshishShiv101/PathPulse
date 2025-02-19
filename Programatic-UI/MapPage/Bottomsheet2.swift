import UIKit
import CoreLocation

class BottomSheetViewController: UIViewController {
    
    // MARK: - Properties
    var cityName: String?
    var weatherInfo: String?
    var cityImageURL: String?
    var cityDescription: String?
    var location: String?
    private var currentLocation: CLLocation?
    private var destinationLocation: CLLocation?
    
    private var guideItems: [GuideItem] = []
    private var cityImages: [String] = []
    private let googleAPIKey = "AIzaSyAkRf97JQAwepJSR6coaCQBQ5WpsOWLNyE"
    private let openWeatherAPIKey = "562caa4db4fe2bf5de1470e5d0f67961"
    
    private var selectedTransportMode: TransportMode = .car {
        didSet {
            updateTransportButtons()
            calculateRouteInfo()
        }
    }
    
    enum TransportMode {
        case car
        case train
    }
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#222222")
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 10
        view.layer.shadowOpacity = 0.3
        return view
    }()
    
    private let transportContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let carButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "car.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        button.layer.cornerRadius = 10
        return button
    }()
    
    private let trainButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "tram.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .clear
        button.layer.cornerRadius = 10
        return button
    }()
    
    private let routeInfoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let cityImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 15
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        imageView.image = UIImage(named: "placeholder") // Add a placeholder image
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let weatherLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.layer.cornerRadius = 12
        label.layer.backgroundColor = UIColor.white.withAlphaComponent(0.1).cgColor
        label.clipsToBounds = true
        label.numberOfLines = 0
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.8)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private let imagesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 15
        layout.minimumLineSpacing = 15
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        return collectionView
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()
            setupLayout()
            updateUI()
            setupTransportButtons()
            imagesCollectionView.dataSource = self
            imagesCollectionView.delegate = self
            fetchCityImage()
            fetchWeatherData()
            
            // Initialize with mock current location (you should replace this with actual location)
            currentLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
            fetchDestinationCoordinates()
        }
    
    private func setupTransportButtons() {
            carButton.addTarget(self, action: #selector(transportButtonTapped(_:)), for: .touchUpInside)
            trainButton.addTarget(self, action: #selector(transportButtonTapped(_:)), for: .touchUpInside)
            updateTransportButtons()
        }
        
        private func updateTransportButtons() {
            carButton.backgroundColor = selectedTransportMode == .car ? UIColor.white.withAlphaComponent(0.2) : .clear
            trainButton.backgroundColor = selectedTransportMode == .train ? UIColor.white.withAlphaComponent(0.2) : .clear
        }
        
        @objc private func transportButtonTapped(_ sender: UIButton) {
            selectedTransportMode = sender == carButton ? .car : .train
        }
        
        private func fetchDestinationCoordinates() {
            guard let city = cityName?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
            let urlString = "https://maps.googleapis.com/maps/api/geocode/json?address=\(city)&key=\(googleAPIKey)"
            
            guard let url = URL(string: urlString) else { return }
            
            URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
                guard let data = data, error == nil else { return }
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    guard let results = json?["results"] as? [[String: Any]],
                          let location = results.first?["geometry"] as? [String: Any],
                          let coordinates = location["location"] as? [String: Double],
                          let lat = coordinates["lat"],
                          let lng = coordinates["lng"] else {
                        return
                    }
                    
                    self?.destinationLocation = CLLocation(latitude: lat, longitude: lng)
                    DispatchQueue.main.async {
                        self?.calculateRouteInfo()
                    }
                } catch {
                    print("Error fetching coordinates: \(error)")
                }
            }.resume()
        }
        
        private func calculateRouteInfo() {
            guard let currentLocation = currentLocation,
                  let destinationLocation = destinationLocation else {
                return
            }
            
            let distance = currentLocation.distance(from: destinationLocation) / 1000 // Convert to kilometers
            
            // Calculate estimated time (this is a simple calculation, in reality you would use Google's Direction API)
            let speedKmH = selectedTransportMode == .car ? 60.0 : 80.0 // Average speed
            let timeHours = distance / speedKmH
            
            let hours = Int(timeHours)
            let minutes = Int((timeHours - Double(hours)) * 60)
            
            let transportEmoji = selectedTransportMode == .car ? "🚗" : "🚂"
            routeInfoLabel.text = "\(transportEmoji) Distance: \(Int(distance))km • Estimated Time: \(hours)h \(minutes)min"
        }
    // MARK: - Helper Methods
    private func getWeatherComment(for temperature: Double, description: String) -> String {
        switch temperature {
        case ..<0:
            return "❄️ It's freezing cold!"
        case 0..<10:
            return "🥶 It's quite chilly."
        case 10..<20:
            return "☁️ It's a bit cool."
        case 20..<30:
            return "🌤 It's warm and pleasant."
        case 30..<40:
            return "🔥 It's hot outside!"
        default:
            return "🌡 The weather is extreme."
        }
    }
    
    private func fetchWeatherData() {
        guard let city = cityName?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(city)&appid=\(openWeatherAPIKey)&units=metric"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil else { return }
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                guard let main = json?["main"] as? [String: Any],
                      let temp = main["temp"] as? Double,
                      let weather = json?["weather"] as? [[String: Any]],
                      let description = weather.first?["description"] as? String else {
                    return
                }
                
                let weatherComment = self?.getWeatherComment(for: temp, description: description)
                
                DispatchQueue.main.async {
                    self?.weatherLabel.text = "\(temp)°C | \(description.capitalized) \(weatherComment ?? "")"
                }
            } catch {
                print("Error fetching weather data: \(error)")
            }
        }.resume()
    }
    
    private func fetchCityImage() {
        guard let city = cityName?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        let urlString = "https://maps.googleapis.com/maps/api/place/textsearch/json?query=\(city)&key=\(googleAPIKey)"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil else { return }
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                guard let results = json?["results"] as? [[String: Any]] else { return }
                
                var imageURLs: [String] = []
                for result in results.prefix(5) { // Fetch from more results (up to 5)
                    if let photos = result["photos"] as? [[String: Any]] {
                        for photo in photos.prefix(2) { // Fetch 2 images per result
                            if let photoRef = photo["photo_reference"] as? String {
                                let imageURL = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=500&photoreference=\(photoRef)&key=\(self?.googleAPIKey ?? "")"
                                imageURLs.append(imageURL)
                            }
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self?.cityImages = imageURLs
                    self?.imagesCollectionView.reloadData()
                }
            } catch {
                print("Error fetching city image: \(error)")
            }
        }.resume()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#222222")
        
        // Add gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(hex: "#222222").cgColor,
            UIColor(hex: "#1a1a1a").cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func updateUI() {
        titleLabel.text = cityName ?? "Unknown City"
        descriptionLabel.text = cityDescription ?? "No description available"
        
        // Load city image
        if let imageURL = cityImageURL, let url = URL(string: imageURL) {
            URLSession.shared.dataTask(with: url) { data, _, error in
                guard let data = data, error == nil else { return }
                DispatchQueue.main.async {
                    self.cityImageView.image = UIImage(data: data)
                }
            }.resume()
        }
    }
    
    // MARK: - Layout Setup
    private func setupLayout() {
        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(weatherLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(imagesCollectionView)
        containerView.addSubview(cityImageView)
        containerView.addSubview(transportContainer)
                transportContainer.addSubview(carButton)
                transportContainer.addSubview(trainButton)
                containerView.addSubview(routeInfoLabel)
                
                [transportContainer, carButton, trainButton, routeInfoLabel].forEach {
                    $0.translatesAutoresizingMaskIntoConstraints = false
                }
                
        [containerView, titleLabel, weatherLabel, descriptionLabel, imagesCollectionView, cityImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            imagesCollectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            imagesCollectionView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imagesCollectionView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imagesCollectionView.heightAnchor.constraint(equalToConstant: 180),
            
            cityImageView.topAnchor.constraint(equalTo: imagesCollectionView.bottomAnchor, constant: 20),
            cityImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            cityImageView.widthAnchor.constraint(equalToConstant: 250),
            cityImageView.heightAnchor.constraint(equalToConstant: 180),
            
            weatherLabel.topAnchor.constraint(equalTo: cityImageView.bottomAnchor, constant: 20),
            weatherLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            weatherLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            descriptionLabel.topAnchor.constraint(equalTo: weatherLabel.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -20),
            transportContainer.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
                      transportContainer.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                      transportContainer.widthAnchor.constraint(equalToConstant: 120),
                      transportContainer.heightAnchor.constraint(equalToConstant: 50),
                      
                      carButton.leadingAnchor.constraint(equalTo: transportContainer.leadingAnchor, constant: 10),
                      carButton.centerYAnchor.constraint(equalTo: transportContainer.centerYAnchor),
                      carButton.widthAnchor.constraint(equalToConstant: 44),
                      carButton.heightAnchor.constraint(equalToConstant: 44),
                      
                      trainButton.trailingAnchor.constraint(equalTo: transportContainer.trailingAnchor, constant: -10),
                      trainButton.centerYAnchor.constraint(equalTo: transportContainer.centerYAnchor),
                      trainButton.widthAnchor.constraint(equalToConstant: 44),
                      trainButton.heightAnchor.constraint(equalToConstant: 44),
                      
                      routeInfoLabel.topAnchor.constraint(equalTo: transportContainer.bottomAnchor, constant: 20),
                      routeInfoLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
                      routeInfoLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
                      routeInfoLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -20)
              
        ])
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Custom Collection View Cell
class ImageCell: UICollectionViewCell {
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 15
        iv.layer.borderWidth = 2
        iv.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        iv.image = UIImage(named: "placeholder") // Add a placeholder image
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        // Add shadow
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 8
        contentView.layer.shadowOpacity = 0.3
    }
    
    func configure(with imageURL: String) {
        if let url = URL(string: imageURL) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
                guard let data = data, error == nil else { return }
                DispatchQueue.main.async {
                    self?.imageView.image = UIImage(data: data)
                }
            }.resume()
        }
    }
}

// MARK: - Collection View DataSource & Delegate
extension BottomSheetViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cityImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
        cell.configure(with: cityImages[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 280, height: 180)
    }
}
