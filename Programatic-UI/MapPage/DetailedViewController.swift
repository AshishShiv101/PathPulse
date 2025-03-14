import UIKit
import CoreLocation

enum WeatherCondition: String {
    case sunny = "sun.max.fill"
    case cloudy = "cloud.fill"
    case rainy = "cloud.rain.fill"
    case storm = "cloud.bolt.rain.fill"
    case snow = "snow"
}

struct HourlyForecast {
    let time: String
    let temp: String
    let condition: WeatherCondition
}

struct DailyForecast {
    let day: String
    let lowTemp: String
    let highTemp: String
    let condition: WeatherCondition
}

class DetailedViews: UIViewController, CLLocationManagerDelegate {
    
    // MARK: - Properties
    private var weatherCollectionView: UICollectionView!
    private var weeklyCollectionView: UICollectionView!
    private let gradientLayer = CAGradientLayer()
    private let locationManager = CLLocationManager()
    private var lastSearchedCity: String?
    private var currentLocationWeather: WeatherData? // Cache for current location
    private var searchedLocationWeather: WeatherData? // Cache for searched location
    private var currentCoordinate: CLLocationCoordinate2D? // Store current location coordinates
    private var currentCityName: String? // Store the current location's city name
    
    // Loading indicator
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var toggleLocationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Current", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 15
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Gradient with #40CBD8
        let gradient = CAGradientLayer()
        gradient.frame = button.bounds
        gradient.colors = [
            UIColor(red: 64/255, green: 203/255, blue: 216/255, alpha: 1.0).cgColor, // #40CBD8
            UIColor(red: 64/255, green: 150/255, blue: 216/255, alpha: 1.0).cgColor // A slightly darker variant
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.cornerRadius = 15
        button.layer.insertSublayer(gradient, at: 0)
        
        button.addTarget(self, action: #selector(toggleLocationTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var locationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.text = "STATE" // Placeholder for state
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private var _cityName: String?
    var cityName: String? {
        get { _cityName }
        set {
            if _cityName != newValue {
                _cityName = newValue
                
                // Split the city and state if available
                if let cityState = newValue {
                    let components = cityState.components(separatedBy: ", ")
                    if components.count >= 2 {
                        let city = components[0] // City name
                        let state = components[1] // State name
                        cityLabel.text = city // Update city label
                        locationLabel.text = state // Update state label
                    } else {
                        // If no state is provided, fallback to the full string for city
                        cityLabel.text = cityState
                        locationLabel.text = "" // Clear state label if no state is available
                    }
                } else {
                    // If newValue is nil, set default values
                    cityLabel.text = "Unknown City"
                    locationLabel.text = "Unknown Location"
                }
                
                // Fetch weather if a valid city is provided
                if let city = newValue, !city.isEmpty {
                    lastSearchedCity = city
                    toggleLocationButton.setTitle("Searched", for: .normal)
                    
                    if searchedLocationWeather == nil || lastSearchedCity != city {
                        showLoadingIndicator()
                        fetchWeatherForCity(city)
                    } else if let cachedWeather = searchedLocationWeather {
                        updateUI(with: cachedWeather)
                    }
                }
            }
        }
    }
    private lazy var cityLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 36, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.text = "CITY" // Placeholder for city
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private lazy var temperatureLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 96, weight: .thin)
        label.textColor = .white
        label.textAlignment = .center
        label.text = "20°"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var conditionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.text = "Sunny"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var additionalDetailsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "Humidity: 45%\nWind: 12 km/h\nUV Index: 6"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let hourlyData: [HourlyForecast] = [
        HourlyForecast(time: "Now", temp: "72°", condition: .sunny),
        HourlyForecast(time: "10AM", temp: "74°", condition: .sunny),
        HourlyForecast(time: "11AM", temp: "78°", condition: .cloudy),
        HourlyForecast(time: "12PM", temp: "81°", condition: .rainy),
        HourlyForecast(time: "1PM", temp: "84°", condition: .sunny),
        HourlyForecast(time: "2PM", temp: "86°", condition: .sunny)
    ]
    
    private let weeklyData: [DailyForecast] = [
        DailyForecast(day: "Mon", lowTemp: "65°", highTemp: "75°", condition: .sunny),
        DailyForecast(day: "Tue", lowTemp: "62°", highTemp: "72°", condition: .cloudy),
        DailyForecast(day: "Wed", lowTemp: "60°", highTemp: "70°", condition: .rainy),
        DailyForecast(day: "Thu", lowTemp: "64°", highTemp: "78°", condition: .storm),
        DailyForecast(day: "Fri", lowTemp: "66°", highTemp: "80°", condition: .sunny),
        DailyForecast(day: "Sat", lowTemp: "68°", highTemp: "82°", condition: .sunny),
        DailyForecast(day: "Sun", lowTemp: "61°", highTemp: "76°", condition: .snow)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        setupUI()
        setupWeatherCollectionView()
        setupWeeklyCollectionView()
        setupLoadingIndicator()
        requestLocation()
    }
    
    // MARK: - Loading Indicator Setup
    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func showLoadingIndicator() {
        DispatchQueue.main.async { [weak self] in
            self?.loadingIndicator.startAnimating()
            self?.view.bringSubviewToFront(self!.loadingIndicator)
        }
    }
    
    private func hideLoadingIndicator() {
        DispatchQueue.main.async { [weak self] in
            self?.loadingIndicator.stopAnimating()
        }
    }
    
    // MARK: - Location Handling
    private func requestLocation() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentCoordinate = location.coordinate
        showLoadingIndicator()
        fetchWeather(for: location.coordinate)
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self, let placemark = placemarks?.first, error == nil else { return }
            if let city = placemark.locality, let state = placemark.administrativeArea {
                DispatchQueue.main.async {
                    self.currentCityName = "\(city), \(state)" // Store city and state
                    self.cityLabel.text = city // Update city label
                    self.locationLabel.text = state // Update state label
                    self.toggleLocationButton.setTitle("Current", for: .normal)
                }
            }
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location:", error.localizedDescription)
        hideLoadingIndicator()
    }
    
    // MARK: - Weather Fetching
    private func fetchWeather(for coordinate: CLLocationCoordinate2D) {
        WeatherService.shared.fetchWeather(for: coordinate) { [weak self] weatherData, error in
            guard let self = self else { return }
            if let weather = weatherData, error == nil {
                DispatchQueue.main.async {
                    if self.toggleLocationButton.title(for: .normal) == "Current" {
                        self.currentLocationWeather = weather
                    } else {
                        self.searchedLocationWeather = weather
                    }
                    self.updateUI(with: weather)
                    self.hideLoadingIndicator()
                }
            } else {
                print("Failed to fetch weather:", error?.localizedDescription ?? "Unknown error")
                DispatchQueue.main.async {
                    self.hideLoadingIndicator()
                }
            }
        }
    }
    private func fetchWeatherForCity(_ city: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(city) { [weak self] placemarks, error in
            guard let self = self else { return }
            if let placemark = placemarks?.first, error == nil {
                let coordinate = placemark.location?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
                if let city = placemark.locality, let state = placemark.administrativeArea {
                    DispatchQueue.main.async {
                        self._cityName = "\(city), \(state)" // Update cityName with city and state
                        self.cityLabel.text = city // Update city label
                        self.locationLabel.text = state // Update state label
                    }
                }
                self.fetchWeather(for: coordinate)
            } else {
                print("Failed to geocode city:", error?.localizedDescription ?? "Unknown error")
                DispatchQueue.main.async {
                    self.hideLoadingIndicator()
                }
            }
        }
    }
    private func updateUI(with weather: WeatherData) {
        temperatureLabel.text = "\(Int(weather.temperature))°"
        conditionLabel.text = weather.description.capitalized
        additionalDetailsLabel.text = "Humidity: \(weather.humidity)%\nWind: \(weather.windSpeed) km/h"
        applyBackgroundGradient(for: weather.icon)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
        toggleLocationButton.layer.sublayers?.first?.frame = toggleLocationButton.bounds
    }
    
    // MARK: - Setup Methods
    private func setupGradientBackground() {
        gradientLayer.colors = [UIColor.systemGray.cgColor, UIColor.darkGray.cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func applyBackgroundGradient(for icon: String) {
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
            if icon == "02n" { self.locationLabel.textColor = .white } else { self.locationLabel.textColor = .black }
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
            if icon == "13n" { self.locationLabel.textColor = .white } else { self.locationLabel.textColor = .black }
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
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.5)
        view.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
        view.layer.insertSublayer(gradientLayer, at: 0)
        CATransaction.commit()
        
        temperatureLabel.textColor = textColor
        conditionLabel.textColor = textColor
        additionalDetailsLabel.textColor = textColor
        cityLabel.textColor = textColor
        backButton.tintColor = textColor
        toggleLocationButton.tintColor = textColor
    }
    
    private func setupUI() {
        [backButton, toggleLocationButton, locationLabel, cityLabel, temperatureLabel, conditionLabel, additionalDetailsLabel].forEach {
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            toggleLocationButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            toggleLocationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            toggleLocationButton.widthAnchor.constraint(equalToConstant: 80),
            toggleLocationButton.heightAnchor.constraint(equalToConstant: 30),
            
            locationLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            locationLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            cityLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 8),
            cityLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            temperatureLabel.topAnchor.constraint(equalTo: cityLabel.bottomAnchor, constant: 0),
            temperatureLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            conditionLabel.topAnchor.constraint(equalTo: temperatureLabel.bottomAnchor, constant: 0),
            conditionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            additionalDetailsLabel.topAnchor.constraint(equalTo: conditionLabel.bottomAnchor, constant: 20),
            additionalDetailsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func setupWeatherCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 20
        layout.itemSize = CGSize(width: 60, height: 100)
        
        weatherCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        weatherCollectionView.backgroundColor = .clear
        weatherCollectionView.delegate = self
        weatherCollectionView.dataSource = self
        weatherCollectionView.register(WeatherCell.self, forCellWithReuseIdentifier: "WeatherCell")
        weatherCollectionView.showsHorizontalScrollIndicator = false
        weatherCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(weatherCollectionView)
        
        NSLayoutConstraint.activate([
            weatherCollectionView.topAnchor.constraint(equalTo: additionalDetailsLabel.bottomAnchor, constant: 20),
            weatherCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            weatherCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            weatherCollectionView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    private func setupWeeklyCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 20
        layout.itemSize = CGSize(width: 80, height: 120)
        
        weeklyCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        weeklyCollectionView.backgroundColor = .clear
        weeklyCollectionView.delegate = self
        weeklyCollectionView.dataSource = self
        weeklyCollectionView.register(WeeklyWeatherCell.self, forCellWithReuseIdentifier: "WeeklyWeatherCell")
        weeklyCollectionView.showsHorizontalScrollIndicator = false
        weeklyCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(weeklyCollectionView)
        
        NSLayoutConstraint.activate([
            weeklyCollectionView.topAnchor.constraint(equalTo: weatherCollectionView.bottomAnchor, constant: 20),
            weeklyCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            weeklyCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            weeklyCollectionView.heightAnchor.constraint(equalToConstant: 120)
        ])
    }
    
    @objc private func backButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func toggleLocationTapped() {
        // Add a subtle animation to the button
        UIView.animate(withDuration: 0.2, animations: {
            self.toggleLocationButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                self.toggleLocationButton.transform = .identity
            }
        }
        
        if toggleLocationButton.title(for: .normal) == "Current" {
            // Switch to last searched city
            if let searchedCity = lastSearchedCity {
                toggleLocationButton.setTitle("Searched", for: .normal)
                
                // Important: Update UI immediately with cached data if available
                if let cachedWeather = searchedLocationWeather {
                    // Update labels directly instead of using cityName setter
                    self._cityName = searchedCity
                    self.cityLabel.text = searchedCity
                    self.locationLabel.text = "Location" // Update state if available
                    self.updateUI(with: cachedWeather)
                } else {
                    // Only fetch if no cached data
                    self.showLoadingIndicator()
                    self._cityName = searchedCity
                    self.cityLabel.text = searchedCity
                    self.locationLabel.text = "Location" // Update state if available
                    self.fetchWeatherForCity(searchedCity)
                }
            }
        } else {
            // Switch to current location
            toggleLocationButton.setTitle("Current", for: .normal)
            
            // Important: Update UI immediately with cached data if available
            if let cachedWeather = currentLocationWeather, let cityName = currentCityName {
                self._cityName = cityName
                self.cityLabel.text = cityName
                self.locationLabel.text = "State" // Update state if available
                self.updateUI(with: cachedWeather)
            } else if let coordinate = currentCoordinate {
                self.showLoadingIndicator()
                if let cityName = currentCityName {
                    self._cityName = cityName
                    self.cityLabel.text = cityName
                    self.locationLabel.text = "State" // Update state if available
                }
                self.fetchWeather(for: coordinate)
            } else {
                self.showLoadingIndicator()
                self.locationManager.requestLocation()
            }
        }
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension DetailedViews: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == weatherCollectionView {
            return hourlyData.count
        } else {
            return weeklyData.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == weatherCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WeatherCell", for: indexPath) as! WeatherCell
            let data = hourlyData[indexPath.item]
            cell.configure(with: data)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WeeklyWeatherCell", for: indexPath) as! WeeklyWeatherCell
            let data = weeklyData[indexPath.item]
            cell.configure(with: data)
            return cell
        }
    }
}

// MARK: - WeatherCell
class WeatherCell: UICollectionViewCell {
    private let timeLabel = UILabel()
    private let tempLabel = UILabel()
    private let weatherIcon = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCellUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCellUI() {
        backgroundColor = .clear
        [timeLabel, tempLabel, weatherIcon].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        timeLabel.font = .systemFont(ofSize: 14, weight: .medium)
        timeLabel.textColor = .white
        timeLabel.textAlignment = .center
        
        weatherIcon.contentMode = .scaleAspectFit
        weatherIcon.tintColor = .white
        
        tempLabel.font = .systemFont(ofSize: 16, weight: .medium)
        tempLabel.textColor = .white
        tempLabel.textAlignment = .center
        
        NSLayoutConstraint.activate([
            timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            timeLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            weatherIcon.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 5),
            weatherIcon.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            weatherIcon.widthAnchor.constraint(equalToConstant: 24),
            weatherIcon.heightAnchor.constraint(equalToConstant: 24),
            
            tempLabel.topAnchor.constraint(equalTo: weatherIcon.bottomAnchor, constant: 5),
            tempLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }
    
    func configure(with data: HourlyForecast) {
        timeLabel.text = data.time
        tempLabel.text = data.temp
        weatherIcon.image = UIImage(systemName: data.condition.rawValue)
    }
}

// MARK: - WeeklyWeatherCell
class WeeklyWeatherCell: UICollectionViewCell {
    private let dayLabel = UILabel()
    private let tempLabel = UILabel()
    private let weatherIcon = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCellUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCellUI() {
        backgroundColor = .clear
        [dayLabel, tempLabel, weatherIcon].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        dayLabel.font = .systemFont(ofSize: 14, weight: .medium)
        dayLabel.textColor = .white
        dayLabel.textAlignment = .center
        
        weatherIcon.contentMode = .scaleAspectFit
        weatherIcon.tintColor = .white
        
        tempLabel.font = .systemFont(ofSize: 16, weight: .medium)
        tempLabel.textColor = .white
        tempLabel.textAlignment = .center
        
        NSLayoutConstraint.activate([
            dayLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            dayLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            weatherIcon.topAnchor.constraint(equalTo: dayLabel.bottomAnchor, constant: 5),
            weatherIcon.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            weatherIcon.widthAnchor.constraint(equalToConstant: 24),
            weatherIcon.heightAnchor.constraint(equalToConstant: 24),
            
            tempLabel.topAnchor.constraint(equalTo: weatherIcon.bottomAnchor, constant: 5),
            tempLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }
    
    func configure(with data: DailyForecast) {
        dayLabel.text = data.day
        tempLabel.text = "\(data.lowTemp) - \(data.highTemp)"
        weatherIcon.image = UIImage(systemName: data.condition.rawValue)
    }
}
