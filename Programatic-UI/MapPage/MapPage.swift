import UIKit
import MapKit
import CoreLocation
import Firebase
import FirebaseFirestore
import FirebaseAuth
class MapPage: UIViewController, CLLocationManagerDelegate, UISearchBarDelegate, MKMapViewDelegate, MKLocalSearchCompleterDelegate, UITableViewDelegate, UITableViewDataSource {
    private let db = Firestore.firestore()
    private var userId: String? {
        return Auth.auth().currentUser?.uid
    }
    private var weatherUpdateTimer: Timer?
    let locationManager = CLLocationManager()
    let mapView = MKMapView()
    var destinationAddress: String?
    var destinationName: String?
    var weatherInfoView: UIView?
    let searchBar = UISearchBar()
    private var bottomSheetTopConstraint: NSLayoutConstraint!
    let sosButton = UIButton()
    private let sosOverlayView = SOSOverlayView()
    private let otherButton = UIButton()
    var recentSearchTitles: [String] = []
    private var searchCompleter = MKLocalSearchCompleter()
    private var searchResults: [MKLocalSearchCompletion] = []
    private var suggestionTableView: UITableView!
    private var displayedLocationCoordinate: CLLocationCoordinate2D?
    private var displayedLocationName: String?
    private var isShowingSearchedLocation = false
    private var alertView: WeatherAlertView?
    private var isKeyboardVisible = false
    private var currentBottomSheetPosition: CGFloat = -135 // Default to collapsed height
    private var shouldRevertToExpanded = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardObservers()
        setupViews()
        setupBottomSheet()
        setupSOSButton()
        setupSOSOverlay()
        setupAlertButton()
        navigationItem.hidesBackButton = true
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
        
        mapView.userTrackingMode = .followWithHeading
        view.bringSubviewToFront(bottomSheetView)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        mapView.addGestureRecognizer(longPressGesture)
        
        addCompassToMap()
        
        searchCompleter.delegate = self
        
        setupSuggestionTableView()
        
        loadSearchHistoryFromFirestore()
        
        locationLabel.text = "Fetching location..."
        
        startWeatherUpdateTimer()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
                        view.addGestureRecognizer(tap)
    }
    @objc private func dismissKeyboard() {
            view.endEditing(true)
        }
    private func setupKeyboardObservers() {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(keyboardWillShow),
                name: UIResponder.keyboardWillShowNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(keyboardWillHide),
                name: UIResponder.keyboardWillHideNotification,
                object: nil
            )
        }
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        // Check if bottom sheet is at expanded height
        if abs(bottomSheetTopConstraint.constant - (-bottomSheetExpandedHeight)) < 1 {
            shouldRevertToExpanded = true // Mark that we need to revert to expanded later
            currentBottomSheetPosition = -bottomSheetExpandedHeight

            // Move to medium height
            UIView.animate(withDuration: duration) {
                self.bottomSheetTopConstraint.constant = -self.bottomSheetMediumHeight
                self.view.layoutIfNeeded()
            }
        }

        isKeyboardVisible = true
    }

        @objc private func keyboardWillHide(notification: NSNotification) {
            guard let userInfo = notification.userInfo,
                  let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
                return
            }

            // If it was at expanded height before keyboard showed, revert to expanded
            if shouldRevertToExpanded {
                UIView.animate(withDuration: duration) {
                    self.bottomSheetTopConstraint.constant = -self.bottomSheetExpandedHeight
                    self.view.layoutIfNeeded()
                }
                shouldRevertToExpanded = false
            }

            isKeyboardVisible = false
        }

        // Clean up observers
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    private func startWeatherUpdateTimer() {
        weatherUpdateTimer?.invalidate()
        
        weatherUpdateTimer = Timer.scheduledTimer(
            withTimeInterval: 600,
            repeats: true
        ) { [weak self] _ in
            guard let self = self else { return }
            if !self.isShowingSearchedLocation, let location = self.locationManager.location {
                self.fetchWeather(for: location.coordinate) { weatherData in
                    if let weatherData = weatherData {
                        print("Weather data fetched for current location: \(weatherData)")
                    } else {
                        print("Failed to fetch weather data for current location")
                    }
                }
            }
        }
    }
    private func saveRecentSearchesToFirestore() {
        guard let userId = userId else {
            print("User not authenticated")
            return
        }
        let searchData: [String: Any] = [
            "recentSearches": recentSearchTitles,
            "timestamp": FieldValue.serverTimestamp()
        ]
        db.collection("users").document(userId).setData(searchData, merge: true) { error in
            if let error = error {
                print("Error saving recent searches to Firestore: \(error.localizedDescription)")
            } else {
                print("Recent searches saved to Firestore: \(self.recentSearchTitles)")
            }
        }
    }

    private func saveAllSearchesToFirestore(_ searchTitle: String) {
        guard let userId = userId else {
            print("User not authenticated")
            return
        }

        let searchData: [String: Any] = [
            "title": searchTitle,
            "timestamp": FieldValue.serverTimestamp(),
            "userId": userId
        ]

        db.collection("allSearches").addDocument(data: searchData) { error in
            if let error = error {
                print("Error saving all searches to Firestore: \(error.localizedDescription)")
            } else {
                print("All searches saved to Firestore: \(searchTitle)")
            }
        }
    }

    private func loadSearchHistoryFromFirestore() {
        guard let userId = userId else {
            print("User not authenticated")
            return
        }

        db.collection("users").document(userId).getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            if let error = error {
                print("Error loading search history: \(error.localizedDescription)")
                return
            }
            if let document = document, document.exists, let data = document.data(),
               let searches = data["recentSearches"] as? [String] {
                self.recentSearchTitles = searches
            } else {
                self.recentSearchTitles = []
            }
            DispatchQueue.main.async {
                self.refreshRecentSearches()
            }
        }
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
        
        suggestionTableView.isHidden = true
        
        saveAllSearchesToFirestore(cityName)
        if let index = recentSearchTitles.firstIndex(of: cityName) {
            recentSearchTitles.remove(at: index)
            recentSearchTitles.insert(cityName, at: 0)
        } else {
            recentSearchTitles.insert(cityName, at: 0)
            if recentSearchTitles.count > 5 {
                recentSearchTitles.removeLast()
            }
        }
        saveRecentSearchesToFirestore()
        refreshRecentSearches()
        locationLabel.text = cityName
        isShowingSearchedLocation = true
        CitySearchHelper.searchForCity(city: cityName, mapView: mapView, locationManager: locationManager) { [weak self] (weatherData, error) in
            guard let self = self else { return }
            if let error = error {
                print("Error searching for city: \(error.localizedDescription)")
                return
            }
            if let weatherData = weatherData {
                DispatchQueue.main.async {
                    self.displayedLocationName = cityName
                    self.displayedLocationCoordinate = CLLocationCoordinate2D(latitude: weatherData.latitude, longitude: weatherData.longitude)
                    self.updateWeatherUI(with: weatherData)

                    let region = MKCoordinateRegion(center: self.displayedLocationCoordinate!, latitudinalMeters: 10000, longitudinalMeters: 10000)
                    self.mapView.setRegion(region, animated: true)
                    self.mapView.removeAnnotations(self.mapView.annotations)
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = self.displayedLocationCoordinate!
                    annotation.title = cityName
                    self.mapView.addAnnotation(annotation)
                }
            }
        }
        searchBar.resignFirstResponder()
    }

    @objc private func openAdditionalView() {
        let detailVC = NewsViewController()
        if let cityName = locationLabel.text {
            detailVC.searchedCity = cityName
        }
        detailVC.modalPresentationStyle = .fullScreen
        present(detailVC, animated: true, completion: nil)
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
        suggestionTableView.isHidden = true // Hide the suggestion table view after selection
        searchBarSearchButtonClicked(searchBar) // Trigger the search
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
        if let userLocation = locationManager.location {
            let coordinate = userLocation.coordinate
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(region, animated: true)
            isShowingSearchedLocation = false // Reset to current location
            displayedLocationCoordinate = coordinate
            fetchWeather(for: coordinate) { [weak self] weatherData in
                if let weatherData = weatherData {
                    self?.updateWeatherUI(with: weatherData)
                }
            }
        } else {
            print("User location not available")
        }
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
    
    private let alertButton: UIButton = {
        let button = UIButton()
        button.setTitle("!", for: .normal)
        button.backgroundColor = UIColor(hex: "#333333")
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 29)
        button.layer.cornerRadius = 35
        return button
    }()
    
    private func setupAlertButton() {
        alertButton.addTarget(self, action: #selector(alertButtonTapped), for: .touchUpInside)
        view.addSubview(alertButton)
        alertButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            alertButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            alertButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -250),
            alertButton.widthAnchor.constraint(equalToConstant: 70),
            alertButton.heightAnchor.constraint(equalToConstant: 70)
        ])
        alertButton.isHidden = true // Hide by default until an alert is detected
        alertButton.backgroundColor = UIColor(hex: "#333333") // Default color
    }
    @objc private func alertButtonTapped() {
        if let currentLocation = locationManager.location?.coordinate {
            fetchWeather(for: currentLocation) { [weak self] weatherData in
                guard let self = self, let weatherData = weatherData else { return }
                let geocoder = CLGeocoder()
                let location = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
                
                geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
                    let locationName = placemarks?.first?.locality ?? "Unknown Location"
                    self.showAlertView(with: weatherData, locationName: locationName)
                    
                    // Update button color based on weather alert
                    if self.isSignificantWeatherChange(weatherData: weatherData) {
                        self.alertButton.backgroundColor = UIColor(hex: "#FF0000") // Red for alert
                    } else {
                        self.alertButton.backgroundColor = UIColor(hex: "#333333") // Normal color
                    }
                }
            }
        } else {
            print("Current location not available")
            // Set to normal color if location unavailable
            alertButton.backgroundColor = UIColor(hex: "#333333")
        }
    }
    private func showAlertView(with weatherData: WeatherData, locationName: String) {
        if alertView != nil {
            alertView?.removeFromSuperview()
        }
        
        let screenBounds = UIScreen.main.bounds
        let cardWidth: CGFloat = 300
        let cardHeight: CGFloat = 200
        
        alertView = WeatherAlertView(frame: CGRect(
            x: (screenBounds.width - cardWidth) / 2,
            y: (screenBounds.height - cardHeight) / 2 - 100,
            width: cardWidth,
            height: cardHeight
        ))
        
        // Check if there's a significant weather change
        if isSignificantWeatherChange(weatherData: weatherData) {
            alertView?.configure(with: locationName, temperature: weatherData.temperature, description: weatherData.description)
        } else {
            alertView?.configureAsNoAlert()
        }
        
        alertView?.closeButton.addTarget(self, action: #selector(dismissAlertView), for: .touchUpInside)
        
        if let alertView = alertView {
            view.addSubview(alertView)
            view.bringSubviewToFront(alertView)
        }
    }

    private func isSignificantWeatherChange(weatherData: WeatherData) -> Bool {
        guard let previousData = previousWeatherData else {
            previousWeatherData = weatherData
            return false // No previous data to compare, so no alert
        }
        
        let temperatureChange = abs(previousData.temperature - weatherData.temperature)
        let humidityChange = abs(previousData.humidity - weatherData.humidity)
        let windSpeedChange = abs(previousData.windSpeed - weatherData.windSpeed)
        
        // Define thresholds for significant change
        return temperatureChange > 5 || humidityChange > 20 || windSpeedChange > 5 || previousData.description != weatherData.description
    }

    private func checkForWeatherChanges(weatherData: WeatherData, location: CLLocationCoordinate2D) {
        guard let previousLoc = previousLocation else {
            previousWeatherData = weatherData
            previousLocation = location
            return
        }
        
        let distance = calculateDistance(location, previousLoc)
        
        if distance <= 30 { // Within 30km radius
            if isSignificantWeatherChange(weatherData: weatherData) {
                showWeatherAlert(weatherData: weatherData, location: location)
            }
        }
        
        previousWeatherData = weatherData
        previousLocation = location
    }


    @objc private func dismissAlertView() {
        alertView?.removeFromSuperview()
        alertView = nil
        
        // Re-check weather to reset button color
        if let currentLocation = locationManager.location?.coordinate {
            fetchWeather(for: currentLocation) { [weak self] weatherData in
                guard let self = self, let weatherData = weatherData else {
                    self?.alertButton.backgroundColor = UIColor(hex: "#333333")
                    return
                }
                if self.isSignificantWeatherChange(weatherData: weatherData) {
                    self.alertButton.backgroundColor = UIColor(hex: "#FF0000")
                } else {
                    self.alertButton.backgroundColor = UIColor(hex: "#333333")
                }
            }
        } else {
            alertButton.backgroundColor = UIColor(hex: "#333333")
        }
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
        mapView.showsCompass = false
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
    
    private let bottomSheetView = UIView()
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
    private let bottomSheetCollapsedHeight: CGFloat = 135
    private let bottomSheetMediumHeight: CGFloat = 300
    private let bottomSheetExpandedHeight: CGFloat = 800
    private func addContentToBottomSheet() {
        let rectangleView = UIView()
        rectangleView.backgroundColor = .systemGray
        rectangleView.layer.cornerRadius = 10
        rectangleView.translatesAutoresizingMaskIntoConstraints = false
        bottomSheetView.addSubview(rectangleView)
        
        let closeCircleView = UIView()
        closeCircleView.backgroundColor = UIColor(white: 1, alpha: 0.2)
        closeCircleView.layer.cornerRadius = 15
        closeCircleView.translatesAutoresizingMaskIntoConstraints = false
        bottomSheetView.addSubview(closeCircleView)
        
        let closeButton = UIButton(type: .system)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(closeBottomSheet), for: .touchUpInside)
        closeCircleView.addSubview(closeButton)
        
        let expandCircleView = UIView()
        expandCircleView.backgroundColor = UIColor(white: 1, alpha: 0.2)
        expandCircleView.layer.cornerRadius = 15
        expandCircleView.translatesAutoresizingMaskIntoConstraints = false
        bottomSheetView.addSubview(expandCircleView)
        
        let expandButton = UIButton(type: .system)
        expandButton.translatesAutoresizingMaskIntoConstraints = false
        expandButton.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right"), for: .normal)
        expandButton.tintColor = .white
        expandButton.addTarget(self, action: #selector(expandBottomSheet), for: .touchUpInside)
        expandCircleView.addSubview(expandButton)
        
        NSLayoutConstraint.activate([
            rectangleView.topAnchor.constraint(equalTo: bottomSheetView.topAnchor, constant: 10),
            rectangleView.centerXAnchor.constraint(equalTo: bottomSheetView.centerXAnchor),
            rectangleView.widthAnchor.constraint(equalToConstant: 60),
            rectangleView.heightAnchor.constraint(equalToConstant: 5),
        ])
        
        NSLayoutConstraint.activate([
            closeCircleView.topAnchor.constraint(equalTo: bottomSheetView.topAnchor, constant: 10),
            closeCircleView.trailingAnchor.constraint(equalTo: bottomSheetView.trailingAnchor, constant: -16),
            closeCircleView.widthAnchor.constraint(equalToConstant: 30),
            closeCircleView.heightAnchor.constraint(equalToConstant: 30),
            
            closeButton.centerXAnchor.constraint(equalTo: closeCircleView.centerXAnchor),
            closeButton.centerYAnchor.constraint(equalTo: closeCircleView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),
        ])
        
        NSLayoutConstraint.activate([
            expandCircleView.topAnchor.constraint(equalTo: bottomSheetView.topAnchor, constant: 10),
            expandCircleView.trailingAnchor.constraint(equalTo: closeCircleView.leadingAnchor, constant: -10),
            expandCircleView.widthAnchor.constraint(equalToConstant: 30),
            expandCircleView.heightAnchor.constraint(equalToConstant: 30),
            
            expandButton.centerXAnchor.constraint(equalTo: expandCircleView.centerXAnchor),
            expandButton.centerYAnchor.constraint(equalTo: expandCircleView.centerYAnchor),
            expandButton.widthAnchor.constraint(equalToConstant: 24),
            expandButton.heightAnchor.constraint(equalToConstant: 24),
        ])
    
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        bottomSheetView.addSubview(searchBar)
        searchBar.barStyle = .default
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Search for Destination..."
        searchBar.tintColor = .black // Sets the cursor and cancel button color
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.textColor = .white
            textField.attributedPlaceholder = NSAttributedString(
                string: "Search for Destination...",
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]
            )
            textField.backgroundColor = .darkGray // Or any other color that fits your design
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
        locationLabel.lineBreakMode = .byTruncatingTail
        locationLabel.numberOfLines = 1
        locationLabel.adjustsFontSizeToFitWidth = false
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            weatherView.topAnchor.constraint(equalTo: suggestionsContainer.bottomAnchor, constant: 20),
            weatherView.leadingAnchor.constraint(equalTo: bottomSheetView.leadingAnchor, constant: 16),
            weatherView.trailingAnchor.constraint(equalTo: bottomSheetView.trailingAnchor, constant: -16),
            weatherView.heightAnchor.constraint(equalToConstant: 220),

            weatherIcon.leadingAnchor.constraint(equalTo: weatherView.leadingAnchor, constant: 20),
            weatherIcon.centerYAnchor.constraint(equalTo: weatherView.centerYAnchor, constant: -40),
            weatherIcon.widthAnchor.constraint(equalToConstant: 160),
            weatherIcon.heightAnchor.constraint(equalToConstant: 160),

            temperatureLabel.topAnchor.constraint(equalTo: weatherView.topAnchor, constant: 20),
            temperatureLabel.centerXAnchor.constraint(equalTo: weatherView.centerXAnchor, constant: 85),

            humidityLabel.topAnchor.constraint(equalTo: temperatureLabel.bottomAnchor, constant: 10),
            humidityLabel.trailingAnchor.constraint(equalTo: weatherView.trailingAnchor, constant: -105),

            windSpeedLabel.topAnchor.constraint(equalTo: humidityLabel.bottomAnchor, constant: 10),
            windSpeedLabel.trailingAnchor.constraint(equalTo: weatherView.trailingAnchor, constant: -81),

            locationLabel.topAnchor.constraint(equalTo: windSpeedLabel.bottomAnchor, constant: 10),
            locationLabel.leadingAnchor.constraint(equalTo: weatherView.leadingAnchor, constant: 20),
            locationLabel.trailingAnchor.constraint(equalTo: weatherView.trailingAnchor, constant: -40)
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

    @objc private func closeBottomSheet() {
        UIView.animate(withDuration: 0.3) {
            self.bottomSheetTopConstraint.constant = -(self.bottomSheetCollapsedHeight)
            self.view.layoutIfNeeded()
        }
        print("Close button tapped - Bottom sheet collapsed")
    }

    @objc private func expandBottomSheet() {
        UIView.animate(withDuration: 0.3) {
            self.bottomSheetTopConstraint.constant = -(self.bottomSheetExpandedHeight)
            self.view.layoutIfNeeded()
        }
        print("Expand button tapped - Bottom sheet expanded")
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
    @objc private func removeRecentSearch(_ sender: UIButton) {
        guard let stackView = sender.superview as? UIStackView,
              let label = stackView.arrangedSubviews.first as? UILabel,
              let title = label.text,
              let index = recentSearchTitles.firstIndex(of: title) else {
            return
        }
        recentSearchTitles.remove(at: index)
        saveRecentSearchesToFirestore()
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
    
    private var isInitialLocationSet = false
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinate = location.coordinate
        
        // Only set the region on the first update
        if !isInitialLocationSet {
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(region, animated: true)
            isInitialLocationSet = true
        }
        
        // Update weather only if not showing a searched location
        if !isShowingSearchedLocation {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Reverse geocoding error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.locationLabel.text = "Location Unknown"
                    }
                    return
                }
                
                if let placemark = placemarks?.first {
                    let city = placemark.locality ?? placemark.subAdministrativeArea ?? "Unknown Location"
                    DispatchQueue.main.async {
                        self.locationLabel.text = city
                        self.displayedLocationName = city
                        self.displayedLocationCoordinate = coordinate
                    }
                    self.fetchWeather(for: coordinate)
                } else {
                    DispatchQueue.main.async {
                        self.locationLabel.text = "Location Unknown"
                    }
                }
            }
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
            
            // Remove existing overlays and annotations
            self.mapView.removeOverlays(self.mapView.overlays)
            self.mapView.removeAnnotations(self.mapView.annotations.filter { $0 is WeatherAnnotation })
            
            let route = response.routes[0]
            self.mapView.addOverlay(route.polyline, level: .aboveRoads)
            let rect = route.polyline.boundingMapRect
            self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
            
            // Add weather annotations along the route
            self.addWeatherAnnotationsAlongRoute(route: route)
        }
    }
    private func addWeatherAnnotationsAlongRoute(route: MKRoute) {
        let polyline = route.polyline
        let pointCount = polyline.pointCount
        let totalDistance = route.distance / 1000

        guard totalDistance > 30 else {
            let midIndex = pointCount / 2
            let midCoordinate = polyline.points()[midIndex].coordinate
            fetchWeather(for: midCoordinate) { [weak self] weatherData in
                guard let self = self, let weatherData = weatherData else { return }
                DispatchQueue.main.async {
                    let annotation = WeatherAnnotation(coordinate: midCoordinate, weatherData: weatherData)
                    self.mapView.addAnnotation(annotation)
                }
            }
            return
        }
        
        // Calculate points at 30 km intervals
        let intervalDistance: CLLocationDistance = 30 // 30 km intervals
        var accumulatedDistance: CLLocationDistance = 0
        var lastCoordinate = polyline.points()[0].coordinate
        
        // Add annotation at the start
        fetchWeather(for: lastCoordinate) { [weak self] weatherData in
            guard let self = self, let weatherData = weatherData else { return }
            DispatchQueue.main.async {
                let annotation = WeatherAnnotation(coordinate: lastCoordinate, weatherData: weatherData)
                self.mapView.addAnnotation(annotation)
            }
        }
        
        // Iterate through route points
        for i in 1..<pointCount {
            let currentCoordinate = polyline.points()[i].coordinate
            let currentLocation = CLLocation(latitude: currentCoordinate.latitude, longitude: currentCoordinate.longitude)
            let lastLocation = CLLocation(latitude: lastCoordinate.latitude, longitude: lastCoordinate.longitude)
            
            accumulatedDistance += currentLocation.distance(from: lastLocation) / 1000 // Distance in km
            
            if accumulatedDistance >= intervalDistance {
                fetchWeather(for: currentCoordinate) { [weak self] weatherData in
                    guard let self = self, let weatherData = weatherData else { return }
                    DispatchQueue.main.async {
                        let annotation = WeatherAnnotation(coordinate: currentCoordinate, weatherData: weatherData)
                        self.mapView.addAnnotation(annotation)
                    }
                }
                accumulatedDistance = 0 // Reset accumulated distance
                lastCoordinate = currentCoordinate
            }
        }
        
        // Add annotation at the end if not too close to the last one
        let endCoordinate = polyline.points()[pointCount - 1].coordinate
        let lastAddedLocation = CLLocation(latitude: lastCoordinate.latitude, longitude: lastCoordinate.longitude)
        let distanceToEnd = lastAddedLocation.distance(from: CLLocation(latitude: endCoordinate.latitude, longitude: endCoordinate.longitude)) / 1000
        
        if distanceToEnd >= 15 { // Ensure last annotation isn't too close (e.g., >15 km)
            fetchWeather(for: endCoordinate) { [weak self] weatherData in
                guard let self = self, let weatherData = weatherData else { return }
                DispatchQueue.main.async {
                    let annotation = WeatherAnnotation(coordinate: endCoordinate, weatherData: weatherData)
                    self.mapView.addAnnotation(annotation)
                }
            }
        }
    }
    class WeatherAnnotation: NSObject, MKAnnotation {
        let coordinate: CLLocationCoordinate2D
        let weatherData: WeatherData
        
        init(coordinate: CLLocationCoordinate2D, weatherData: WeatherData) {
            self.coordinate = coordinate
            self.weatherData = weatherData
            super.init()
        }
        
        var title: String? {
            return weatherData.description.capitalized
        }
        
        var subtitle: String? {
            return "\(Int(weatherData.temperature))°C"
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
    private func getWeatherIcon(for iconCode: String) -> UIImage? {
        switch iconCode {
        case "01d", "01n": // Clear sky
            return UIImage(systemName: "sun.max.fill")
        case "02d", "02n": // Few clouds
            return UIImage(systemName: "cloud.sun.fill")
        case "03d", "03n", "04d", "04n": // Scattered or broken clouds
            return UIImage(systemName: "cloud.fill")
        case "09d", "09n", "10d", "10n": // Rain
            return UIImage(systemName: "cloud.rain.fill")
        case "11d", "11n": // Thunderstorm
            return UIImage(systemName: "cloud.bolt.fill")
        case "13d", "13n": // Snow
            return UIImage(systemName: "cloud.snow.fill")
        case "50d", "50n": // Mist/Fog
            return UIImage(systemName: "cloud.fog.fill")
        default:
            return UIImage(systemName: "questionmark.circle.fill")
        }
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Skip user location annotation
        if annotation is MKUserLocation {
            return nil
        }
        
        // Handle WeatherAnnotation
        if let weatherAnnotation = annotation as? WeatherAnnotation {
            let identifier = "WeatherAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: weatherAnnotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = weatherAnnotation
            }
            
            // Set weather icon based on weather condition
            let iconImage = getWeatherIcon(for: weatherAnnotation.weatherData.icon)
            annotationView?.image = iconImage?.withRenderingMode(.alwaysOriginal)
            
            // Adjust size of the icon
            let iconSize: CGFloat = 40
            annotationView?.frame = CGRect(x: 0, y: 0, width: iconSize, height: iconSize)
            
            return annotationView
        }
        
        // Default annotation handling
        let identifier = "Pin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier) as MKAnnotationView
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }
        return annotationView
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
            weatherInfoView = createWeatherInfoView()
            if let weatherInfoView = weatherInfoView {
                view.addSubview(weatherInfoView)
            }
            fetchWeather(for: coordinate) { [weak self] weatherData in
            }
        }
    }
    private func createWeatherInfoView() -> UIView {
        let screenBounds = UIScreen.main.bounds
        let cardWidth: CGFloat = 220
        let cardHeight: CGFloat = 250
        
        let weatherView = UIView()
        weatherView.layer.cornerRadius = 16
        weatherView.layer.shadowColor = UIColor.black.cgColor
        weatherView.layer.shadowOpacity = 0.25
        weatherView.layer.shadowOffset = CGSize(width: 0, height: 6)
        weatherView.layer.shadowRadius = 8
        weatherView.frame = CGRect(
            x: (screenBounds.width - cardWidth) / 2,
            y: (screenBounds.height - cardHeight) / 2,
            width: cardWidth,
            height: cardHeight
        )
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = weatherView.bounds
        gradientLayer.colors = [UIColor(hex: "#333333").cgColor, UIColor(hex: "#222222").cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.cornerRadius = 16
        weatherView.layer.insertSublayer(gradientLayer, at: 0)
        
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("×", for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = UIColor(hex: "#444444").withAlphaComponent(0.8)
        closeButton.layer.cornerRadius = 14
        closeButton.frame = CGRect(x: weatherView.frame.width - 38, y: 12, width: 28, height: 28)
        closeButton.addTarget(self, action: #selector(dismissWeatherInfoView), for: .touchUpInside)
        weatherView.addSubview(closeButton)
        
        let weatherIcon = UIImageView()
        weatherIcon.frame = CGRect(x: (weatherView.frame.width - 130) / 2, y: 20, width: 130, height: 130)
        weatherIcon.contentMode = .scaleAspectFit
        weatherIcon.tintColor = .white
        weatherIcon.tag = 101
        weatherView.addSubview(weatherIcon)
        
        let titleLabel = UILabel()
        titleLabel.text = "Fetching weather..."
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .white
        titleLabel.tag = 201
        titleLabel.frame = CGRect(x: 10, y: 135, width: weatherView.frame.width - 20, height: 24)
        weatherView.addSubview(titleLabel)
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = ""
        descriptionLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        descriptionLabel.textAlignment = .center
        descriptionLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        descriptionLabel.tag = 202
        descriptionLabel.frame = CGRect(x: 10, y: 168, width: weatherView.frame.width - 20, height: 20)
        weatherView.addSubview(descriptionLabel)
        
        let locationLabel = UILabel()
        locationLabel.text = "Fetching location..."
        locationLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        locationLabel.textAlignment = .center
        locationLabel.textColor = .white
        locationLabel.backgroundColor = UIColor(hex: "#444444").withAlphaComponent(0.7)
        locationLabel.layer.cornerRadius = 10
        locationLabel.clipsToBounds = true
        locationLabel.tag = 203
        locationLabel.frame = CGRect(x: 20, y: 198, width: weatherView.frame.width - 40, height: 32)
        locationLabel.numberOfLines = 2
        weatherView.addSubview(locationLabel)
        
        weatherView.tag = 1000
        return weatherView
    }
    
    @objc private func dismissWeatherInfoView() {
        weatherInfoView?.removeFromSuperview()
        weatherInfoView = nil
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
                    imageView.tintColor = nil
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
            gradientLayer.colors = [UIColor(hex: "#333333").cgColor, UIColor(hex: "#222222").cgColor]
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
            descriptionLabel.text = "Please try again later"
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
    
    private var previousWeatherData: WeatherData?
    private var previousLocation: CLLocationCoordinate2D?
    
    private func calculateDistance(_ coord1: CLLocationCoordinate2D, _ coord2: CLLocationCoordinate2D) -> CLLocationDistance {
        let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return location1.distance(from: location2) / 1000 // Convert to kilometers
    }
        
    private var lastAlertLocationName: String?
    private func showWeatherAlert(weatherData: WeatherData, location: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            let locationName = placemarks?.first?.locality ?? "Unknown Location"
            
            if self.lastAlertLocationName == locationName {
                return
            }
            self.lastAlertLocationName = locationName
            
            let alert = UIAlertController(
                title: "Weather Update (30km Radius)",
                message: "Significant weather change detected at \(locationName): \(weatherData.description), \(Int(weatherData.temperature))°C",
                preferredStyle: .alert
            )
            
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    private func fetchWeather(for coordinate: CLLocationCoordinate2D, completion: @escaping (WeatherData?) -> Void) {
        WeatherService.shared.fetchWeather(for: coordinate) { [weak self] (weatherData, error) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching weather: \(error.localizedDescription)")
                    self.updateWeatherInfoViewWithError()
                    self.alertButton.isHidden = true
                    self.alertButton.backgroundColor = UIColor(hex: "#333333")
                    completion(nil)
                    return
                }
                guard let weatherData = weatherData else {
                    print("No weather data received")
                    self.updateWeatherInfoViewWithError()
                    self.alertButton.isHidden = true
                    self.alertButton.backgroundColor = UIColor(hex: "#333333")
                    completion(nil)
                    return
                }
                let geocoder = CLGeocoder()
                let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
                    if let error = error {
                        print("Reverse geocoding error: \(error.localizedDescription)")
                        self.updateWeatherInfoView(weatherData, locationName: nil)
                        self.checkForWeatherChanges(weatherData: weatherData, location: coordinate)
                        if self.isSignificantWeatherChange(weatherData: weatherData) {
                            self.alertButton.isHidden = false
                            self.alertButton.backgroundColor = UIColor(hex: "#FF0000")
                        } else {
                            self.alertButton.isHidden = true
                            self.alertButton.backgroundColor = UIColor(hex: "#333333")
                        }
                        completion(weatherData)
                        return
                    }
                    let locationName = placemarks?.first?.locality ?? placemarks?.first?.name ?? "Unknown location"
                    self.updateWeatherInfoView(weatherData, locationName: locationName)
                    self.checkForWeatherChanges(weatherData: weatherData, location: coordinate)
                    if self.isSignificantWeatherChange(weatherData: weatherData) {
                        self.alertButton.isHidden = false // Show button
                        self.alertButton.backgroundColor = UIColor(hex: "#FF0000") // Red for alert
                    } else {
                        self.alertButton.isHidden = true // Hide button
                        self.alertButton.backgroundColor = UIColor(hex: "#333333") // Default color
                    }
                    completion(weatherData)
                }
            }
        }
    }
    private class WeatherAlertView: UIView {
        let gradientLayer = CAGradientLayer()
        let titleLabel = UILabel()
        let messageLabel = UILabel()
        let closeButton = UIButton(type: .system)
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setupView()
        }
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        private func setupView() {
            layer.cornerRadius = 16
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.25
            layer.shadowOffset = CGSize(width: 0, height: 6)
            layer.shadowRadius = 8
            backgroundColor = .clear
            isUserInteractionEnabled = true
            
            gradientLayer.frame = bounds
            gradientLayer.colors = [UIColor(hex: "#333333").cgColor, UIColor(hex: "#222222").cgColor]
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
            gradientLayer.cornerRadius = 16
            layer.insertSublayer(gradientLayer, at: 0)
            
            titleLabel.text = "Weather Alert"
            titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
            titleLabel.textColor = .white
            titleLabel.textAlignment = .center
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            addSubview(titleLabel)
            
            messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
            messageLabel.textColor = UIColor.white.withAlphaComponent(0.9)
            messageLabel.textAlignment = .center
            messageLabel.numberOfLines = 0
            messageLabel.translatesAutoresizingMaskIntoConstraints = false
            addSubview(messageLabel)
            
            closeButton.setTitle("×", for: .normal)
            closeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
            closeButton.setTitleColor(.white, for: .normal)
            closeButton.backgroundColor = UIColor(hex: "#444444").withAlphaComponent(0.8)
            closeButton.layer.cornerRadius = 14
            closeButton.translatesAutoresizingMaskIntoConstraints = false
            addSubview(closeButton)
            
            NSLayoutConstraint.activate([
                closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 12),
                closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
                closeButton.widthAnchor.constraint(equalToConstant: 28),
                closeButton.heightAnchor.constraint(equalToConstant: 28),
                
                titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 50),
                titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
                titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
                
                messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
                messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
                messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
                messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
            ])
            configureAsNoAlert()
        }
        override func layoutSubviews() {
            super.layoutSubviews()
            gradientLayer.frame = bounds
        }
        func configureAsNoAlert() {
            messageLabel.text = "No Alert"
        }
        func configure(with locationName: String, temperature: Double, description: String) {
            messageLabel.text = "Significant weather change detected at \(locationName): \(description), \(Int(temperature))°C"
        }
    }
}
