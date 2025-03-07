import UIKit
import MapKit
import CoreLocation

class MapPage: UIViewController, CLLocationManagerDelegate, UISearchBarDelegate, MKMapViewDelegate, MKLocalSearchCompleterDelegate, UITableViewDelegate, UITableViewDataSource {
    let locationManager = CLLocationManager()
    let mapView = MKMapView()
    var destinationAddress: String?
    var destinationName: String?
    private let bottomSheetView = UIView()
    var weatherInfoView: UIView?
    let searchBar = UISearchBar()
    private var bottomSheetTopConstraint: NSLayoutConstraint!
    private let bottomSheetCollapsedHeight: CGFloat = 135
    private let bottomSheetMediumHeight: CGFloat = 300
    private let bottomSheetExpandedHeight: CGFloat = 800
    let sosButton = UIButton()
    private let sosOverlayView = SOSOverlayView()
    private let otherButton = UIButton()
    var recentSearchTitles: [String] = []
    private var searchCompleter = MKLocalSearchCompleter()
    private var searchResults: [MKLocalSearchCompletion] = []
    private var suggestionTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupBottomSheet()
        setupSOSButton()
        setupSOSOverlay()
        navigationItem.hidesBackButton = true
        
        // Location setup
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        searchBar.delegate = self
        mapView.showsUserLocation = true
        mapView.delegate = self
        setupLocationButton()
        setupOtherButton()
        setupToggleView()
        mapView.showsCompass = true
        mapView.userTrackingMode = .followWithHeading
        view.bringSubviewToFront(bottomSheetView)
        sosOverlayView.translatesAutoresizingMaskIntoConstraints = false
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        mapView.addGestureRecognizer(longPressGesture)
        addCompassToMap()
        searchCompleter.delegate = self
        setupSuggestionTableView()
        
        locationLabel.text = "Fetching location..."
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            suggestionTableView.isHidden = true
            searchResults.removeAll()
            suggestionTableView.reloadData()
        } else {
            searchCompleter.queryFragment = searchText
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let cityName = searchBar.text, !cityName.isEmpty else {
            return
        }
        
        suggestionTableView?.isHidden = true
        
        if !recentSearchTitles.contains(cityName) {
            recentSearchTitles.insert(cityName, at: 0)
            if recentSearchTitles.count > 5 {
                recentSearchTitles.removeLast()
            }
            refreshRecentSearches()
        }
        
        locationLabel.text = cityName
        CitySearchHelper.searchForCity(city: cityName, mapView: mapView, locationManager: locationManager) { [weak self] (weatherData, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            if let weatherData = weatherData {
                DispatchQueue.main.async {
                    self.updateWeatherUI(with: weatherData)
                    
                    let hasSeenAlert = UserDefaults.standard.bool(forKey: "hasSeenFirstSearchAlert")
                    if !hasSeenAlert {
                        let alert = UIAlertController(
                            title: "For More Details",
                            message: "Long tap on the route\nPull up the bottom sheet for more Weather and News details",
                            preferredStyle: .alert
                        )
                        
                        let attributedTitle = NSAttributedString(string: "For More Details", attributes: [
                            .foregroundColor: UIColor.white,
                            .font: UIFont.boldSystemFont(ofSize: 17)
                        ])
                        alert.setValue(attributedTitle, forKey: "attributedTitle")
                        
                        let attributedMessage = NSAttributedString(string: "Long tap on the route\nPull up the bottom sheet for more Weather and News details", attributes: [
                            .foregroundColor: UIColor(red: 64/255, green: 203/255, blue: 216/255, alpha: 1),
                            .font: UIFont.systemFont(ofSize: 13)
                        ])
                        alert.setValue(attributedMessage, forKey: "attributedMessage")
                        
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        okAction.setValue(UIColor.white, forKey: "titleTextColor")
                        alert.addAction(okAction)
                        
                        if let subview = alert.view.subviews.first?.subviews.first?.subviews.first {
                            subview.backgroundColor = UIColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1)
                            subview.layer.cornerRadius = 12
                        }
                        
                        self.present(alert, animated: true, completion: nil)
                        UserDefaults.standard.set(true, forKey: "hasSeenFirstSearchAlert")
                    }
                }
            }
        }
        
        searchBar.resignFirstResponder()
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        suggestionTableView.isHidden = searchResults.isEmpty
        suggestionTableView.reloadData()
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error.localizedDescription)")
        suggestionTableView.isHidden = true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "SuggestionCell")
        let suggestion = searchResults[indexPath.row]
        cell.textLabel?.text = suggestion.title
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.text = suggestion.subtitle
        cell.detailTextLabel?.textColor = .lightGray
        cell.backgroundColor = UIColor(hex: "#333333")
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedSuggestion = searchResults[indexPath.row]
        searchBar.text = selectedSuggestion.title
        suggestionTableView.isHidden = true
        searchBarSearchButtonClicked(searchBar)
    }
    
    private func addCompassToMap() {
        let compassButton = MKCompassButton(mapView: mapView)
        compassButton.compassVisibility = .visible
        compassButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(compassButton)
        NSLayoutConstraint.activate([
            compassButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            compassButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30)
        ])
    }
    
    private let weatherView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#222222")
        view.layer.cornerRadius = 15
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let temperatureLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 50, weight: .bold)
        label.textColor = UIColor(hex: "#FF8C00")
        label.textAlignment = .center
        label.text = "--°C"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let weatherIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let humidityLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor(hex: "40CBD8")
        label.textAlignment = .center
        label.text = "Humidity: --%"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let windSpeedLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor(hex: "40CBD8")
        label.textAlignment = .center
        label.text = "Wind: -- m/s"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = UIColor(hex: "222222")
        label.textAlignment = .center
        label.text = ""
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    @objc private func locationButtonTapped() {
        locationManager.startUpdatingLocation()
    }
    
    @objc private func sosButtonTapped() {
        sosTappedButton.toggle()
    }
    
    private var sosTappedButton: Bool = false {
        didSet {
            sosOverlayView.isHidden = !sosTappedButton
        }
    }
    
    private func setupOtherButton() {
        otherButton.layer.cornerRadius = 35
        otherButton.clipsToBounds = true
        otherButton.layer.borderColor = UIColor.black.cgColor
        otherButton.layer.borderWidth = 3.5
        otherButton.addTarget(self, action: #selector(otherButtonTapped), for: .touchUpInside)
        view.addSubview(otherButton)
        otherButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            otherButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            otherButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 70),
            otherButton.widthAnchor.constraint(equalToConstant: 70),
            otherButton.heightAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    private var selectedButton: UIButton?
    private let toggleView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#333333")
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.layer.cornerRadius = 15
        view.clipsToBounds = true
        return view
    }()
    
    private func setupToggleView() {
        view.addSubview(toggleView)
        NSLayoutConstraint.activate([
            toggleView.trailingAnchor.constraint(equalTo: otherButton.trailingAnchor),
            toggleView.widthAnchor.constraint(equalTo: otherButton.widthAnchor),
            toggleView.topAnchor.constraint(equalTo: otherButton.bottomAnchor, constant: 10),
            toggleView.heightAnchor.constraint(equalToConstant: 150)
        ])
        
        let standardButton = createButton(withSystemImage: "map.fill", action: #selector(standardButtonTapped))
        let satelliteButton = createButton(withSystemImage: "globe.americas.fill", action: #selector(hybridButtonTapped))
        let buttonStackView = UIStackView(arrangedSubviews: [standardButton, satelliteButton])
        buttonStackView.axis = .vertical
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 10
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        
        toggleView.addSubview(buttonStackView)
        NSLayoutConstraint.activate([
            buttonStackView.topAnchor.constraint(equalTo: toggleView.topAnchor, constant: 10),
            buttonStackView.leadingAnchor.constraint(equalTo: toggleView.leadingAnchor, constant: 5),
            buttonStackView.trailingAnchor.constraint(equalTo: toggleView.trailingAnchor, constant: -5),
            buttonStackView.bottomAnchor.constraint(equalTo: toggleView.bottomAnchor, constant: -10)
        ])
        otherButton.setTitle("Map", for: .normal)
        otherButton.backgroundColor = UIColor(hex: "#333333")
        otherButton.setBackgroundImage(nil, for: .normal)
        selectButton(standardButton)
    }
    
    private func createButton(withSystemImage systemImageName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .custom)
        let image = UIImage(systemName: systemImageName)?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 30, weight: .bold)).withTintColor(.white, renderingMode: .alwaysOriginal)
        button.setImage(image, for: .normal)
        button.tintColor = .none
        button.backgroundColor = UIColor(hex: "#333333")
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: action, for: .touchUpInside)
        let size: CGFloat = 50
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: size),
            button.widthAnchor.constraint(equalToConstant: size)
        ])
        button.layer.cornerRadius = size / 2
        button.clipsToBounds = true
        return button
    }
    
    @objc private func otherButtonTapped() {
        otherButton.setTitle("Map", for: .normal)
        otherButton.backgroundColor = UIColor(hex: "#333333")
        otherButton.setBackgroundImage(nil, for: .normal)
        if toggleView.isHidden {
            toggleView.transform = CGAffineTransform(translationX: 0, y: -20)
            toggleView.alpha = 0
            toggleView.isHidden = false
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                self.toggleView.transform = .identity
                self.toggleView.alpha = 1.0
            })
        } else {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
                self.toggleView.transform = CGAffineTransform(translationX: 0, y: -20)
                self.toggleView.alpha = 0
            }) { _ in
                self.toggleView.isHidden = true
                self.toggleView.transform = .identity
            }
        }
    }
    
    @objc private func standardButtonTapped(_ sender: UIButton) {
        selectButton(sender)
        mapView.mapType = .standard
    }
    
    @objc private func hybridButtonTapped(_ sender: UIButton) {
        selectButton(sender)
        mapView.mapType = .hybrid
    }
    
    private func selectButton(_ button: UIButton) {
        selectedButton?.layer.borderWidth = 0
        selectedButton?.layer.borderColor = UIColor.clear.cgColor
        selectedButton?.backgroundColor = UIColor(hex: "#333333")
        
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.systemYellow.cgColor
        button.backgroundColor = UIColor(hex: "#40cbd8")
        
        selectedButton = button
    }
    
    private func setupSOSButton() {
        sosButton.setTitle("SOS", for: .normal)
        sosButton.backgroundColor = UIColor(hex: "#333333")
        sosButton.setTitleColor(.white, for: .normal)
        sosButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        sosButton.layer.cornerRadius = 35
        sosButton.addTarget(self, action: #selector(sosButtonTapped), for: .touchUpInside)
        view.addSubview(sosButton)
        sosButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sosButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            sosButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -250),
            sosButton.widthAnchor.constraint(equalToConstant: 70),
            sosButton.heightAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    private func setupSOSOverlay() {
        sosOverlayView.translatesAutoresizingMaskIntoConstraints = false
        sosOverlayView.isHidden = true
        view.addSubview(sosOverlayView)
        sosOverlayView.addContactIcon(iconName: "cross.circle.fill", label: "Ambulance", number: "102")
        sosOverlayView.addContactIcon(iconName: "shield.fill", label: "Police", number: "100")
        sosOverlayView.addContactIcon(iconName: "figure.stand.dress", label: "Helpline", number: "1091")
        sosOverlayView.layer.zPosition = 0
        NSLayoutConstraint.activate([
            sosOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            sosOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            sosOverlayView.topAnchor.constraint(equalTo: view.topAnchor, constant: 220),
            sosOverlayView.heightAnchor.constraint(equalToConstant: 140)
        ])
    }
    
    private func setupViews() {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        mapView.mapType = .standard
        mapView.showsTraffic = true
        mapView.showsUserLocation = true
    }
    
    private func setupBottomSheet() {
        bottomSheetView.backgroundColor = UIColor(hex: "#333333")
        bottomSheetView.layer.cornerRadius = 18
        bottomSheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        bottomSheetView.clipsToBounds = true
        view.addSubview(bottomSheetView)
        bottomSheetView.translatesAutoresizingMaskIntoConstraints = false
        bottomSheetView.layer.zPosition = 1
        let defaultOffset: CGFloat = 170
        bottomSheetTopConstraint = bottomSheetView.topAnchor.constraint(equalTo: view.bottomAnchor, constant: -(bottomSheetCollapsedHeight + defaultOffset))
        NSLayoutConstraint.activate([
            bottomSheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomSheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomSheetView.heightAnchor.constraint(equalToConstant: bottomSheetExpandedHeight),
            bottomSheetTopConstraint
        ])
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        bottomSheetView.addGestureRecognizer(panGesture)
        addContentToBottomSheet()
    }
    
    let humidityIcon = UIImageView(image: UIImage(systemName: "drop.fill"))
    let windIcon = UIImageView(image: UIImage(systemName: "wind"))
    
    func updateWeatherUI(with weatherData: WeatherData) {
        DispatchQueue.main.async {
            self.temperatureLabel.text = "\(Int(weatherData.temperature))°C"
            
            if let humiditySFIcon = UIImage(systemName: "drop.fill") {
                let humidityAttachment = NSTextAttachment()
                humidityAttachment.image = humiditySFIcon
                humidityAttachment.bounds = CGRect(x: 0, y: -2, width: 18, height: 18)
                let humidityString = NSMutableAttributedString(string: " \(weatherData.humidity)%")
                humidityString.insert(NSAttributedString(attachment: humidityAttachment), at: 0)
                self.humidityLabel.attributedText = humidityString
            }
            
            if let windSFIcon = UIImage(systemName: "wind") {
                let windAttachment = NSTextAttachment()
                windAttachment.image = windSFIcon
                windAttachment.bounds = CGRect(x: 0, y: -2, width: 18, height: 18)
                let windString = NSMutableAttributedString(string: " \(weatherData.windSpeed) m/s")
                windString.insert(NSAttributedString(attachment: windAttachment), at: 0)
                self.windSpeedLabel.attributedText = windString
            }
            
            if let iconUrl = URL(string: "https://openweathermap.org/img/wn/\(weatherData.icon)@2x.png") {
                URLSession.shared.dataTask(with: iconUrl) { data, _, error in
                    if let data = data, error == nil {
                        DispatchQueue.main.async {
                            self.weatherIcon.image = UIImage(data: data)
                        }
                    }
                }.resume()
            }
            
            self.applyBackgroundGradient(for: weatherData.icon)
        }
    }
    
    private func applyBackgroundGradient(for icon: String) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = weatherView.bounds
        gradientLayer.cornerRadius = 15
        gradientLayer.masksToBounds = true
        let textColor: UIColor
        
        switch icon {
        case "01d":
            gradientLayer.colors = [UIColor(red: 1.0, green: 0.8, blue: 0.3, alpha: 1.0).cgColor, UIColor(red: 0.7, green: 0.5, blue: 0.2, alpha: 1.0).cgColor]
            textColor = .white
        case "01n":
            gradientLayer.colors = [UIColor(red: 0.2, green: 0.2, blue: 0.4, alpha: 1.0).cgColor, UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0).cgColor]
            textColor = .lightGray
            self.locationLabel.textColor = .white
        case "02d", "02n":
            gradientLayer.colors = [UIColor(red: 0.6, green: 0.7, blue: 0.9, alpha: 1.0).cgColor, UIColor(red: 0.4, green: 0.5, blue: 0.8, alpha: 1.0).cgColor]
            textColor = .black
            if icon == "02n" { self.locationLabel.textColor = .white }
        case "03d", "03n":
            gradientLayer.colors = [UIColor(red: 0.5, green: 0.5, blue: 0.6, alpha: 1.0).cgColor, UIColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 1.0).cgColor]
            textColor = .white
            if icon == "03n" { self.locationLabel.textColor = .white }
        case "04d", "04n":
            gradientLayer.colors = [UIColor(red: 0.4, green: 0.4, blue: 0.5, alpha: 1.0).cgColor, UIColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1.0).cgColor]
            textColor = .lightGray
            if icon == "04n" { self.locationLabel.textColor = .white }
        case "09d", "09n":
            gradientLayer.colors = [UIColor(red: 0.3, green: 0.4, blue: 0.6, alpha: 1.0).cgColor, UIColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1.0).cgColor]
            textColor = .white
            if icon == "09n" { self.locationLabel.textColor = .white }
        case "10d":
            gradientLayer.colors = [UIColor(red: 0.4, green: 0.6, blue: 0.8, alpha: 1.0).cgColor, UIColor(red: 0.3, green: 0.4, blue: 0.7, alpha: 1.0).cgColor]
            textColor = .black
        case "10n":
            gradientLayer.colors = [UIColor(red: 0.2, green: 0.3, blue: 0.6, alpha: 1.0).cgColor, UIColor(red: 0.1, green: 0.1, blue: 0.3, alpha: 1.0).cgColor]
            textColor = .lightGray
            self.locationLabel.textColor = .white
        case "11d", "11n":
            gradientLayer.colors = [UIColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 1.0).cgColor, UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0).cgColor]
            textColor = .white
            if icon == "11n" { self.locationLabel.textColor = .white }
        case "13d", "13n":
            gradientLayer.colors = [UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0).cgColor, UIColor(red: 0.6, green: 0.7, blue: 0.9, alpha: 1.0).cgColor]
            textColor = .black
            if icon == "13n" { self.locationLabel.textColor = .white }
        case "50d", "50n":
            gradientLayer.colors = [UIColor(red: 0.6, green: 0.6, blue: 0.7, alpha: 1.0).cgColor, UIColor(red: 0.4, green: 0.4, blue: 0.5, alpha: 1.0).cgColor]
            textColor = .white
            if icon == "50n" { self.locationLabel.textColor = .white }
        default:
            gradientLayer.colors = [UIColor.systemGray.cgColor, UIColor.darkGray.cgColor]
            textColor = .white
        }
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        
        weatherView.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
        weatherView.layer.insertSublayer(gradientLayer, at: 0)
        
        self.temperatureLabel.textColor = textColor
        self.humidityLabel.textColor = textColor
        self.windSpeedLabel.textColor = textColor
        
        self.humidityIcon.tintColor = textColor
        self.windIcon.tintColor = textColor
    }
    
    private func setupSuggestionTableView() {
        suggestionTableView = UITableView()
        suggestionTableView.delegate = self
        suggestionTableView.dataSource = self
        suggestionTableView.backgroundColor = UIColor(hex: "#333333")
        suggestionTableView.layer.cornerRadius = 10
        suggestionTableView.isHidden = true
        suggestionTableView.translatesAutoresizingMaskIntoConstraints = false
        bottomSheetView.addSubview(suggestionTableView)
        
        NSLayoutConstraint.activate([
            suggestionTableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 5),
            suggestionTableView.leadingAnchor.constraint(equalTo: bottomSheetView.leadingAnchor, constant: 8),
            suggestionTableView.trailingAnchor.constraint(equalTo: bottomSheetView.trailingAnchor, constant: -8),
            suggestionTableView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    private func addContentToBottomSheet() {
        let rectangleView = UIView()
        rectangleView.backgroundColor = .systemGray
        rectangleView.layer.cornerRadius = 10
        rectangleView.translatesAutoresizingMaskIntoConstraints = false
        bottomSheetView.addSubview(rectangleView)
        NSLayoutConstraint.activate([
            rectangleView.topAnchor.constraint(equalTo: bottomSheetView.topAnchor, constant: 10),
            rectangleView.centerXAnchor.constraint(equalTo: bottomSheetView.centerXAnchor),
            rectangleView.widthAnchor.constraint(equalToConstant: 60),
            rectangleView.heightAnchor.constraint(equalToConstant: 5)
        ])
        
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        bottomSheetView.addSubview(searchBar)
        searchBar.barStyle = .default
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Search for Destination..."
        searchBar.tintColor = .black
        searchBar.backgroundImage = UIImage()
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = .white
            textField.layer.cornerRadius = 15
            textField.clipsToBounds = true
            textField.textColor = .black
            textField.font = UIFont.systemFont(ofSize: 16)
            textField.leftView?.tintColor = .black
        }
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: rectangleView.bottomAnchor, constant: 40),
            searchBar.leadingAnchor.constraint(equalTo: bottomSheetView.leadingAnchor, constant: 5),
            searchBar.trailingAnchor.constraint(equalTo: bottomSheetView.trailingAnchor, constant: -5),
            searchBar.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        let suggestionsContainer = UIView()
        suggestionsContainer.translatesAutoresizingMaskIntoConstraints = false
        suggestionsContainer.backgroundColor = UIColor(hex: "#333333")
        suggestionsContainer.layer.cornerRadius = 12
        suggestionsContainer.layer.borderWidth = 1
        suggestionsContainer.layer.borderColor = UIColor.systemGray4.cgColor
        suggestionsContainer.layer.shadowColor = UIColor.black.cgColor
        suggestionsContainer.layer.shadowOpacity = 0.1
        suggestionsContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        suggestionsContainer.layer.shadowRadius = 4
        bottomSheetView.addSubview(suggestionsContainer)
        
        let suggestionsStack = UIStackView()
        suggestionsStack.axis = .vertical
        suggestionsStack.spacing = 12
        suggestionsStack.translatesAutoresizingMaskIntoConstraints = false
        suggestionsStack.backgroundColor = .clear
        suggestionsContainer.addSubview(suggestionsStack)
        
        for title in recentSearchTitles {
            let entryStack = UIStackView()
            entryStack.axis = .horizontal
            entryStack.distribution = .fill
            entryStack.alignment = .center
            entryStack.spacing = 8
            entryStack.backgroundColor = UIColor.systemGray6
            entryStack.layer.cornerRadius = 8
            entryStack.isLayoutMarginsRelativeArrangement = true
            entryStack.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
            
            let label = UILabel()
            label.text = title
            label.textColor = .black
            label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            
            let crossButton = UIButton(type: .system)
            crossButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            crossButton.tintColor = .systemGray
            crossButton.addTarget(self, action: #selector(removeRecentSearch(_:)), for: .touchUpInside)
            
            crossButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                crossButton.widthAnchor.constraint(equalToConstant: 24),
                crossButton.heightAnchor.constraint(equalToConstant: 24)
            ])
            
            entryStack.addArrangedSubview(label)
            entryStack.addArrangedSubview(crossButton)
            suggestionsStack.addArrangedSubview(entryStack)
        }
        NSLayoutConstraint.activate([
            suggestionsContainer.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 12),
            suggestionsContainer.leadingAnchor.constraint(equalTo: bottomSheetView.leadingAnchor, constant: 10),
            suggestionsContainer.trailingAnchor.constraint(equalTo: bottomSheetView.trailingAnchor, constant: -10),
            suggestionsContainer.heightAnchor.constraint(equalToConstant: 180),
            
            suggestionsStack.topAnchor.constraint(equalTo: suggestionsContainer.topAnchor, constant: 12),
            suggestionsStack.leadingAnchor.constraint(equalTo: suggestionsContainer.leadingAnchor, constant: 8),
            suggestionsStack.trailingAnchor.constraint(equalTo: suggestionsContainer.trailingAnchor, constant: -8),
            suggestionsStack.bottomAnchor.constraint(lessThanOrEqualTo: suggestionsContainer.bottomAnchor, constant: -12)
        ])
        
        weatherView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showDetailedView))
        weatherView.addGestureRecognizer(tapGesture)
        
        bottomSheetView.addSubview(weatherView)
        weatherView.addSubview(weatherIcon)
        weatherView.addSubview(temperatureLabel)
        weatherView.addSubview(locationLabel)
        weatherView.addSubview(humidityLabel)
        weatherView.addSubview(windSpeedLabel)
        
        NSLayoutConstraint.activate([
            weatherView.topAnchor.constraint(equalTo: suggestionsContainer.bottomAnchor, constant: 20),
            weatherView.leadingAnchor.constraint(equalTo: bottomSheetView.leadingAnchor, constant: 16),
            weatherView.trailingAnchor.constraint(equalTo: bottomSheetView.trailingAnchor, constant: -16),
            weatherView.heightAnchor.constraint(equalToConstant: 220),
            weatherIcon.leadingAnchor.constraint(equalTo: weatherView.leadingAnchor, constant: 20),
            weatherIcon.centerYAnchor.constraint(equalTo: weatherView.centerYAnchor),
            weatherIcon.widthAnchor.constraint(equalToConstant: 120),
            weatherIcon.heightAnchor.constraint(equalToConstant: 120),
            temperatureLabel.topAnchor.constraint(equalTo: weatherView.topAnchor, constant: 20),
            temperatureLabel.centerXAnchor.constraint(equalTo: weatherView.centerXAnchor),
            humidityLabel.topAnchor.constraint(equalTo: temperatureLabel.bottomAnchor, constant: 10),
            humidityLabel.trailingAnchor.constraint(equalTo: weatherView.trailingAnchor, constant: -20),
            windSpeedLabel.topAnchor.constraint(equalTo: humidityLabel.bottomAnchor, constant: 10),
            windSpeedLabel.trailingAnchor.constraint(equalTo: weatherView.trailingAnchor, constant: -20),
            locationLabel.topAnchor.constraint(equalTo: windSpeedLabel.bottomAnchor, constant: 10),
            locationLabel.leadingAnchor.constraint(equalTo: weatherView.leadingAnchor, constant: 40)
        ])
        
        let additionalCardView = UIView()
        additionalCardView.translatesAutoresizingMaskIntoConstraints = false
        additionalCardView.backgroundColor = UIColor(hex: "#222222")
        additionalCardView.layer.cornerRadius = 15
        additionalCardView.layer.shadowColor = UIColor.black.cgColor
        additionalCardView.layer.shadowOpacity = 0.2
        additionalCardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        additionalCardView.layer.shadowRadius = 4
        additionalCardView.isUserInteractionEnabled = true
        
        let additionalTapGesture = UITapGestureRecognizer(target: self, action: #selector(openAdditionalView))
        additionalCardView.addGestureRecognizer(additionalTapGesture)
        
        let newsIcon = UIImageView(image: UIImage(systemName: "newspaper"))
        newsIcon.translatesAutoresizingMaskIntoConstraints = false
        newsIcon.tintColor = UIColor(hex: "#40cbd8")
        newsIcon.contentMode = .scaleAspectFit
        
        let newsLabel = UILabel()
        newsLabel.translatesAutoresizingMaskIntoConstraints = false
        newsLabel.text = "See the latest news updates "
        newsLabel.font = UIFont.boldSystemFont(ofSize: 16)
        newsLabel.textColor = .white
        newsLabel.numberOfLines = 2
        newsLabel.textAlignment = .left
        
        additionalCardView.addSubview(newsIcon)
        additionalCardView.addSubview(newsLabel)
        bottomSheetView.addSubview(additionalCardView)
        
        NSLayoutConstraint.activate([
            additionalCardView.topAnchor.constraint(equalTo: weatherView.bottomAnchor, constant: 20),
            additionalCardView.leadingAnchor.constraint(equalTo: bottomSheetView.leadingAnchor, constant: 16),
            additionalCardView.trailingAnchor.constraint(equalTo: bottomSheetView.trailingAnchor, constant: -16),
            additionalCardView.heightAnchor.constraint(equalToConstant: 150),
            newsIcon.centerXAnchor.constraint(equalTo: additionalCardView.centerXAnchor),
            newsIcon.topAnchor.constraint(equalTo: additionalCardView.topAnchor, constant: 20),
            newsIcon.widthAnchor.constraint(equalToConstant: 60),
            newsIcon.heightAnchor.constraint(equalToConstant: 60),
            newsLabel.topAnchor.constraint(equalTo: newsIcon.bottomAnchor, constant: 10),
            newsLabel.centerXAnchor.constraint(equalTo: additionalCardView.centerXAnchor),
            newsLabel.leadingAnchor.constraint(greaterThanOrEqualTo: additionalCardView.leadingAnchor, constant: 20),
            newsLabel.trailingAnchor.constraint(lessThanOrEqualTo: additionalCardView.trailingAnchor, constant: -20)
        ])
    }
    
    private func refreshRecentSearches() {
        bottomSheetView.subviews.forEach { view in
            if let stackView = view as? UIStackView, stackView.tag == 100 {
                stackView.removeFromSuperview()
            }
        }
        
        let recentSearchesContainer = UIStackView()
        recentSearchesContainer.tag = 100
        recentSearchesContainer.axis = .vertical
        recentSearchesContainer.spacing = 12
        recentSearchesContainer.translatesAutoresizingMaskIntoConstraints = false
        bottomSheetView.addSubview(recentSearchesContainer)
        
        NSLayoutConstraint.activate([
            recentSearchesContainer.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 20),
            recentSearchesContainer.leadingAnchor.constraint(equalTo: bottomSheetView.leadingAnchor, constant: 16),
            recentSearchesContainer.trailingAnchor.constraint(equalTo: bottomSheetView.trailingAnchor, constant: -16)
        ])
        
        if recentSearchTitles.isEmpty {
            let spacer = UIView()
            spacer.heightAnchor.constraint(equalToConstant: 20).isActive = true
            recentSearchesContainer.addArrangedSubview(spacer)
            
            let noHistoryLabel = UILabel()
            noHistoryLabel.text = "No history available"
            noHistoryLabel.textColor = .gray
            noHistoryLabel.font = UIFont.systemFont(ofSize: 16)
            noHistoryLabel.textAlignment = .center
            recentSearchesContainer.addArrangedSubview(noHistoryLabel)
        } else {
            for title in recentSearchTitles {
                let entryStack = UIStackView()
                entryStack.axis = .horizontal
                entryStack.distribution = .fill
                entryStack.alignment = .center
                entryStack.spacing = 8
                entryStack.isUserInteractionEnabled = true
                
                let label = UILabel()
                label.text = title
                label.textColor = .white
                label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
                
                let crossButton = UIButton(type: .system)
                crossButton.setImage(UIImage(systemName: "xmark"), for: .normal)
                crossButton.tintColor = .systemGray
                crossButton.addTarget(self, action: #selector(removeRecentSearch(_:)), for: .touchUpInside)
                
                crossButton.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    crossButton.widthAnchor.constraint(equalToConstant: 24),
                    crossButton.heightAnchor.constraint(equalToConstant: 24)
                ])
                
                entryStack.addArrangedSubview(label)
                entryStack.addArrangedSubview(crossButton)
                recentSearchesContainer.addArrangedSubview(entryStack)
                
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(historyCardTapped(_:)))
                entryStack.addGestureRecognizer(tapGesture)
                entryStack.accessibilityLabel = title
            }
        }
        
        if let suggestionTableView = suggestionTableView {
            bottomSheetView.bringSubviewToFront(suggestionTableView)
        }
    }
    
    @objc private func historyCardTapped(_ sender: UITapGestureRecognizer) {
        guard let entryStack = sender.view as? UIStackView,
              let cityName = entryStack.accessibilityLabel else {
            return
        }
        
        searchBar.text = cityName
        searchBarSearchButtonClicked(searchBar)
    }
    
    @objc private func openAdditionalView() {
        let detailVC = NewsViewController()
        detailVC.modalPresentationStyle = .fullScreen
        present(detailVC, animated: true, completion: nil)
    }
    
    @objc private func removeRecentSearch(_ sender: UIButton) {
        guard let stackView = sender.superview as? UIStackView,
              let label = stackView.arrangedSubviews.first as? UILabel,
              let title = label.text,
              let index = recentSearchTitles.firstIndex(of: title) else {
            return
        }
        
        recentSearchTitles.remove(at: index)
        refreshRecentSearches()
    }
    
    @objc private func showDetailedView() {
        guard let cityName = locationLabel.text, !cityName.isEmpty else {
            print("Error: City name is empty or nil")
            return
        }
        
        let detailedVC = DetailedViews()
        detailedVC.cityName = cityName
        
        if let navigationController = navigationController {
            navigationController.pushViewController(detailedVC, animated: true)
        } else {
            print("Warning: navigationController is nil. Presenting modally instead.")
            let navController = UINavigationController(rootViewController: detailedVC)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true, completion: nil)
        }
    }
    
    @objc private func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: view)
        let velocity = recognizer.velocity(in: view)
        if translation.y < 0 {
            bottomSheetTopConstraint.constant = max(-bottomSheetExpandedHeight, bottomSheetTopConstraint.constant + translation.y)
        } else {
            bottomSheetTopConstraint.constant = min(-bottomSheetCollapsedHeight, bottomSheetTopConstraint.constant + translation.y)
        }
        recognizer.setTranslation(.zero, in: view)
        
        if recognizer.state == .ended {
            let targetPosition: CGFloat
            let currentPosition = -bottomSheetTopConstraint.constant
            
            if currentPosition > (bottomSheetExpandedHeight + bottomSheetMediumHeight) / 2 {
                targetPosition = -bottomSheetExpandedHeight
            } else if currentPosition > (bottomSheetMediumHeight + bottomSheetCollapsedHeight) / 2 {
                targetPosition = -bottomSheetMediumHeight
            } else {
                targetPosition = -bottomSheetCollapsedHeight
            }
            UIView.animate(withDuration: 0.3) {
                self.bottomSheetTopConstraint.constant = targetPosition
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func fetchWeather(for coordinate: CLLocationCoordinate2D) {
        WeatherService.shared.fetchWeather(for: coordinate) { [weak self] (weatherData, error) in
            if let error = error {
                print("Error fetching weather: \(error.localizedDescription)")
                return
            }
            if let weatherData = weatherData {
                DispatchQueue.main.async {
                    self?.updateWeatherUI(with: weatherData)
                }
            }
        }
    }
    
    private func setupLocationButton() {
        let locationButton = UIButton(type: .system)
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular, scale: .medium)
        let locationImage = UIImage(systemName: "location.fill", withConfiguration: largeConfig)?.withTintColor(.white, renderingMode: .alwaysOriginal)
        locationButton.setImage(locationImage, for: .normal)
        locationButton.backgroundColor = UIColor(hex: "#333333")
        locationButton.layer.cornerRadius = 35
        locationButton.addTarget(self, action: #selector(locationButtonTapped), for: .touchUpInside)
        view.addSubview(locationButton)
        locationButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            locationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            locationButton.bottomAnchor.constraint(equalTo: sosButton.topAnchor, constant: -20),
            locationButton.widthAnchor.constraint(equalToConstant: 70),
            locationButton.heightAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinate = location.coordinate
        
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: true)
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            if let placemark = placemarks?.first {
                let city = placemark.locality ?? placemark.subAdministrativeArea ?? "Unknown Location"
                DispatchQueue.main.async {
                    self.locationLabel.text = city
                }
            } else {
                DispatchQueue.main.async {
                    self.locationLabel.text = "Location Unknown"
                }
            }
            self.fetchWeather(for: coordinate)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        locationLabel.text = "Location Error"
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            locationLabel.text = "Location Access Denied"
        default:
            break
        }
    }
    func drawRoute(to destination: CLLocationCoordinate2D) {
        guard let userLocation = locationManager.location?.coordinate else {
            print("User location not available")
            return
        }
        let sourcePlacemark = MKPlacemark(coordinate: userLocation)
        let destinationPlacemark = MKPlacemark(coordinate: destination)
        
        let sourceItem = MKMapItem(placemark: sourcePlacemark)
        let destinationItem = MKMapItem(placemark: destinationPlacemark)
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceItem
        directionRequest.destination = destinationItem
        directionRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { [weak self] response, error in
            guard let self = self else { return }
            if let error = error {
                print("Error calculating directions: \(error.localizedDescription)")
                return
            }
            guard let response = response else { return }
            self.mapView.removeOverlays(self.mapView.overlays)
            let route = response.routes[0]
            self.mapView.addOverlay(route.polyline, level: .aboveRoads)
            let rect = route.polyline.boundingMapRect
            self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
        }
    }
    
    func navigateToAddress(_ address: String, name: String?) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { [weak self] placemarks, error in
            guard let self = self else { return }
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                return
            }
            guard let placemark = placemarks?.first, let location = placemark.location else {
                print("Location not found")
                return
            }
            self.drawRoute(to: location.coordinate)
            let annotation = MKPointAnnotation()
            annotation.coordinate = location.coordinate
            annotation.title = name ?? address
            self.mapView.addAnnotation(annotation)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.lineWidth = 4
            
            if let subtitle = polyline.subtitle {
                let flags = subtitle.split(separator: ",")
                let isShortest = flags[0] == "true"
                renderer.strokeColor = isShortest ? .blue : UIColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 1.0)
                print("Rendering polyline - shortest: \(isShortest)")
            } else {
                renderer.strokeColor = .blue
                print("No subtitle found for polyline")
            }
            
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            let location = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            weatherInfoView?.removeFromSuperview()
            weatherInfoView = createWeatherInfoView(at: location)
            if let weatherInfoView = weatherInfoView {
                view.addSubview(weatherInfoView)
            }
            fetchWeather(for: coordinate) { [weak self] weatherData in
            }
        }
    }
    private func createWeatherInfoView(at location: CGPoint) -> UIView {
        let weatherView = UIView()
        weatherView.layer.cornerRadius = 12
        weatherView.layer.shadowColor = UIColor.black.cgColor
        weatherView.layer.shadowOpacity = 0.2
        weatherView.layer.shadowOffset = CGSize(width: 0, height: 4)
        weatherView.layer.shadowRadius = 6
        weatherView.frame = CGRect(x: location.x - 110, y: location.y - 120, width: 220, height: 260)
        weatherView.backgroundColor = UIColor(hex: "#222222")
        
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("×", for: .normal)
        closeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.frame = CGRect(x: weatherView.frame.width - 30, y: 10, width: 20, height: 20)
        closeButton.addTarget(self, action: #selector(dismissWeatherInfoView), for: .touchUpInside)
        weatherView.addSubview(closeButton)
        
        let weatherIcon = UIImageView()
        weatherIcon.frame = CGRect(x: (weatherView.frame.width - 120) / 2, y: 30, width: 120, height: 120)
        weatherIcon.contentMode = .scaleAspectFit
        weatherIcon.tintColor = .white
        weatherIcon.tag = 101
        weatherView.addSubview(weatherIcon)
        
        let titleLabel = UILabel()
        titleLabel.text = "Fetching weather..."
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .white
        titleLabel.tag = 201
        titleLabel.frame = CGRect(x: 10, y: 160, width: weatherView.frame.width - 20, height: 20)
        weatherView.addSubview(titleLabel)
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = ""
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textAlignment = .center
        descriptionLabel.textColor = .white
        descriptionLabel.tag = 202
        descriptionLabel.frame = CGRect(x: 10, y: 185, width: weatherView.frame.width - 20, height: 20)
        weatherView.addSubview(descriptionLabel)
        
        let locationLabel = UILabel()
        locationLabel.text = "Fetching location..."
        locationLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        locationLabel.textAlignment = .center
        locationLabel.textColor = .black
        locationLabel.tag = 203
        locationLabel.frame = CGRect(x: 10, y: 210, width: weatherView.frame.width - 20, height: 40)
        locationLabel.numberOfLines = 2
        weatherView.addSubview(locationLabel)
        
        weatherInfoView?.tag = 1000
        return weatherView
    }
    
    @objc private func dismissWeatherInfoView() {
        weatherInfoView?.removeFromSuperview()
    }
    
    private func updateWeatherInfoView(_ weatherData: WeatherData, locationName: String?) {
        guard let weatherInfoView = weatherInfoView else { return }
        if let titleLabel = weatherInfoView.viewWithTag(201) as? UILabel {
            titleLabel.text = "Temp: \(weatherData.temperature)°C"
        }
        if let descriptionLabel = weatherInfoView.viewWithTag(202) as? UILabel {
            descriptionLabel.text = weatherData.description.capitalized
        }
        if let iconImageView = weatherInfoView.viewWithTag(101) as? UIImageView {
            updateWeatherIcon(iconImageView, with: weatherData.icon)
        }
        if let locationLabel = weatherInfoView.viewWithTag(203) as? UILabel {
            locationLabel.text = locationName ?? "Location unavailable"
        }
        updateWeatherBackground(for: weatherInfoView, condition: weatherData.description.lowercased())
    }
    
    private func updateWeatherIcon(_ imageView: UIImageView, with iconCode: String) {
        let iconUrlString = "https://openweathermap.org/img/wn/\(iconCode)@2x.png"
        guard let iconUrl = URL(string: iconUrlString) else { return }
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: iconUrl), let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    imageView.image = image
                }
            }
        }
    }
    
    private func updateWeatherBackground(for view: UIView, condition: String) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.cornerRadius = view.layer.cornerRadius
        switch condition {
        case let str where str.contains("clear"):
            gradientLayer.colors = [UIColor(hex: "#FFD700").cgColor, UIColor(hex: "#FFA500").cgColor]
        case let str where str.contains("cloud"):
            gradientLayer.colors = [UIColor(hex: "#B0BEC5").cgColor, UIColor(hex: "#78909C").cgColor]
        case let str where str.contains("rain"):
            gradientLayer.colors = [UIColor(hex: "#4682B4").cgColor, UIColor(hex: "#1E3A5F").cgColor]
        case let str where str.contains("storm"):
            gradientLayer.colors = [UIColor(hex: "#2C3E50").cgColor, UIColor(hex: "#000000").cgColor]
        case let str where str.contains("snow"):
            gradientLayer.colors = [UIColor(hex: "#FFFFFF").cgColor, UIColor(hex: "#D3D3D3").cgColor]
        default:
            gradientLayer.colors = [UIColor(hex: "#222222").cgColor, UIColor(hex: "#000000").cgColor]
        }
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        DispatchQueue.main.async {
            view.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
            view.layer.insertSublayer(gradientLayer, at: 0)
        }
    }
    
    private func updateWeatherInfoViewWithError() {
        guard let weatherInfoView = weatherInfoView else { return }
        if let titleLabel = weatherInfoView.viewWithTag(201) as? UILabel {
            titleLabel.text = "Weather unavailable"
        }
        if let descriptionLabel = weatherInfoView.viewWithTag(202) as? UILabel {
            descriptionLabel.text = "Please try again later."
        }
        if let locationLabel = weatherInfoView.viewWithTag(203) as? UILabel {
            locationLabel.text = "Location unavailable"
        }
        if let iconImageView = weatherInfoView.viewWithTag(101) as? UIImageView {
            iconImageView.image = UIImage(systemName: "exclamationmark.triangle.fill")
            iconImageView.tintColor = .red
        }
        updateWeatherBackground(for: weatherInfoView, condition: "error")
    }
    
    private func fetchWeather(for coordinate: CLLocationCoordinate2D, completion: @escaping (WeatherData?) -> Void) {
        WeatherService.shared.fetchWeather(for: coordinate) { [weak self] weatherData, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching weather: \(error.localizedDescription)")
                    self.updateWeatherInfoViewWithError()
                    completion(nil)
                    return
                }
                if let weatherData = weatherData {
                    let geocoder = CLGeocoder()
                    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    geocoder.reverseGeocodeLocation(location) { placemarks, error in
                        if let error = error {
                            print("Reverse geocoding error: \(error.localizedDescription)")
                            self.updateWeatherInfoView(weatherData, locationName: nil)
                            completion(weatherData)
                            return
                        }
                        if let placemark = placemarks?.first {
                            let locationName = placemark.locality ?? placemark.name ?? "Unknown location"
                            self.updateWeatherInfoView(weatherData, locationName: locationName)
                        } else {
                            self.updateWeatherInfoView(weatherData, locationName: nil)
                        }
                        completion(weatherData)
                    }
                } else {
                    self.updateWeatherInfoViewWithError()
                    completion(nil)
                }
            }
        }
    }
}
