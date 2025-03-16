import UIKit
import CoreLocation

enum WeatherCondition: String {
    case sunny = "sun.max.fill"
    case clearNight = "moon.fill"
    case cloudy = "cloud.fill"
    case rainy = "cloud.rain.fill"
    case storm = "cloud.bolt.rain.fill"
    case snow = "snowflake"
    
    static func fromIcon(_ icon: String) -> WeatherCondition {
        switch icon {
        case "01d": return .sunny
        case "01n": return .clearNight
        case "02d", "03d", "04d", "02n", "03n", "04n": return .cloudy
        case "09d", "09n", "10d", "10n": return .rainy
        case "11d", "11n": return .storm
        case "13d", "13n": return .snow
        default: return .cloudy
        }
    }
    
    func getWeatherTag() -> String {
        switch self {
        case .sunny: return "Grab your shades, it’s a solar party!"
        case .clearNight: return "Stargazing tonight? The sky’s your canvas!"
        case .cloudy: return "Perfect day for a cozy book indoors."
        case .rainy: return "Don’t forget your umbrella, rain’s on parade!"
        case .storm: return "Batten down the hatches, it’s wild out there!"
        case .snow: return "Snowball fight or hot cocoa? Your call!"
        }
    }
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
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var hourly24CollectionView: UICollectionView!
    private var weeklyCollectionView: UICollectionView!
    private let gradientLayer = CAGradientLayer()
    private let locationManager = CLLocationManager()
    private var lastSearchedCity: String?
    private var currentLocationWeather: WeatherData?
    private var searchedLocationWeather: WeatherData?
    private var currentCoordinate: CLLocationCoordinate2D?
    private var currentCityName: String?
    private var isShowingSearchedCity = false
    
    private var hourly24ForecastData: [HourlyForecast] = []
    private var weeklyForecastData: [DailyForecast] = []
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private lazy var humidityIconView: UIImageView = {
            let icon = UIImageView(image: UIImage(systemName: "drop.fill"))
            icon.tintColor = .white
            icon.translatesAutoresizingMaskIntoConstraints = false
            return icon
        }()
        
        private lazy var humidityLabel: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 18, weight: .light) // Updated font size and weight
            label.textColor = .white
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
        
        private lazy var windIconView: UIImageView = {
            let icon = UIImageView(image: UIImage(systemName: "wind"))
            icon.tintColor = .white
            icon.translatesAutoresizingMaskIntoConstraints = false
            return icon
        }()
        
        private lazy var windLabel: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 18, weight: .light) // Updated font size and weight
            label.textColor = .white
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
        
        private lazy var pressureIconView: UIImageView = {
            let icon = UIImageView(image: UIImage(systemName: "gauge"))
            icon.tintColor = .white
            icon.translatesAutoresizingMaskIntoConstraints = false
            return icon
        }()
        
        private lazy var pressureLabel: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 18, weight: .light) // Updated font size and weight
            label.textColor = .white
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
        
        private lazy var visibilityIconView: UIImageView = {
            let icon = UIImageView(image: UIImage(systemName: "eye.fill"))
            icon.tintColor = .white
            icon.translatesAutoresizingMaskIntoConstraints = false
            return icon
        }()
        
    
    private lazy var visibilityLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        button.layer.cornerRadius = 18
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.4
        button.layer.shadowOffset = CGSize(width: 0, height: 3)
        button.layer.shadowRadius = 5
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let gradient = CAGradientLayer()
        gradient.frame = button.bounds
        gradient.colors = [
            UIColor(red: 64/255, green: 203/255, blue: 216/255, alpha: 1.0).cgColor,
            UIColor(red: 64/255, green: 150/255, blue: 216/255, alpha: 1.0).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.cornerRadius = 18
        button.layer.insertSublayer(gradient, at: 0)
        
        button.addTarget(self, action: #selector(toggleLocationTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var locationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.text = "STATE"
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var cityLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 44, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.text = "CITY"
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var temperatureLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 110, weight: .thin)
        label.textColor = .white
        label.textAlignment = .center
        label.text = "20°"
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var weatherIconView: UIImageView = {
        let icon = UIImageView()
        icon.contentMode = .scaleAspectFit
        icon.tintColor = .white
        icon.alpha = 0
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.layer.shadowColor = UIColor.white.cgColor
        icon.layer.shadowOpacity = 0.8
        icon.layer.shadowRadius = 5
        icon.layer.shadowOffset = .zero
        return icon
    }()
    
    private lazy var conditionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.text = "Sunny"
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var weatherTagLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "Weather tip goes here!"
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var additionalDetailsView: UIView = {
            let view = UIView()
            // Remove the solid background color and add a blur effect
            view.layer.cornerRadius = 15
            view.layer.shadowColor = UIColor.black.cgColor
            view.layer.shadowOpacity = 0.3
            view.layer.shadowOffset = CGSize(width: 0, height: 2)
            view.layer.shadowRadius = 5
            view.alpha = 0
            view.translatesAutoresizingMaskIntoConstraints = false
            
            // Add a UIVisualEffectView for the frosted glass effect
            let blurEffect = UIBlurEffect(style: .systemThinMaterial)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.translatesAutoresizingMaskIntoConstraints = false
            blurEffectView.layer.cornerRadius = 15
            blurEffectView.clipsToBounds = true
            view.addSubview(blurEffectView)
            
            // Add a vibrancy effect to make the icons and labels pop
            let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect, style: .label)
            let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
            vibrancyEffectView.translatesAutoresizingMaskIntoConstraints = false
            blurEffectView.contentView.addSubview(vibrancyEffectView)
            
            // Constraints for blur and vibrancy views
            NSLayoutConstraint.activate([
                blurEffectView.topAnchor.constraint(equalTo: view.topAnchor),
                blurEffectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                blurEffectView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                blurEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                
                vibrancyEffectView.topAnchor.constraint(equalTo: blurEffectView.topAnchor),
                vibrancyEffectView.leadingAnchor.constraint(equalTo: blurEffectView.leadingAnchor),
                vibrancyEffectView.trailingAnchor.constraint(equalTo: blurEffectView.trailingAnchor),
                vibrancyEffectView.bottomAnchor.constraint(equalTo: blurEffectView.bottomAnchor)
            ])
            
            return view
        }()
    
    private lazy var hourly24Label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .left
        label.text = "24-Hour Forecast"
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var weeklyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .left
        label.text = "6-Day Forecast"
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var _cityName: String?
    var cityName: String? {
        get { _cityName }
        set {
            if _cityName != newValue {
                _cityName = newValue
                updateCityLabels()
                if let city = newValue, !city.isEmpty {
                    lastSearchedCity = city
                    isShowingSearchedCity = true
                    toggleLocationButton.setTitle("Searched", for: .normal)
                    showLoadingIndicator()
                    fetchWeatherForCity(city)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        setupGradientBackground()
        addSubviews()
        setupConstraints()
        setupLoadingIndicator()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if lastSearchedCity != nil && isShowingSearchedCity {
            fetchWeatherForCity(lastSearchedCity!)
        } else {
            requestLocation()
        }
        animateUIIn()
    }
    
    // MARK: - Setup Methods
    private func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
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
    
    private func setupGradientBackground() {
        gradientLayer.colors = [UIColor.systemGray.cgColor, UIColor.darkGray.cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func addSubviews() {
        contentView.addSubview(backButton)
        contentView.addSubview(toggleLocationButton)
        contentView.addSubview(locationLabel)
        contentView.addSubview(cityLabel)
        contentView.addSubview(temperatureLabel)
        contentView.addSubview(weatherIconView)
        contentView.addSubview(conditionLabel)
        contentView.addSubview(weatherTagLabel)
        contentView.addSubview(additionalDetailsView)
        
        additionalDetailsView.addSubview(humidityIconView)
        additionalDetailsView.addSubview(humidityLabel)
        additionalDetailsView.addSubview(windIconView)
        additionalDetailsView.addSubview(windLabel)
        additionalDetailsView.addSubview(pressureIconView)
        additionalDetailsView.addSubview(pressureLabel)
        additionalDetailsView.addSubview(visibilityIconView)
        additionalDetailsView.addSubview(visibilityLabel)
        
        contentView.addSubview(hourly24Label)
        contentView.addSubview(weeklyLabel)
        
        let hourly24Layout = UICollectionViewFlowLayout()
        hourly24Layout.scrollDirection = .horizontal
        hourly24Layout.minimumLineSpacing = 20
        hourly24Layout.itemSize = CGSize(width: 60, height: 120)
        hourly24CollectionView = UICollectionView(frame: .zero, collectionViewLayout: hourly24Layout)
        hourly24CollectionView.backgroundColor = .clear
        hourly24CollectionView.delegate = self
        hourly24CollectionView.dataSource = self
        hourly24CollectionView.register(WeatherCell.self, forCellWithReuseIdentifier: "WeatherCell")
        hourly24CollectionView.showsHorizontalScrollIndicator = false
        hourly24CollectionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(hourly24CollectionView)
        
        let weeklyLayout = UICollectionViewFlowLayout()
        weeklyLayout.scrollDirection = .horizontal
        weeklyLayout.minimumLineSpacing = 20
        weeklyLayout.itemSize = CGSize(width: 80, height: 140)
        weeklyCollectionView = UICollectionView(frame: .zero, collectionViewLayout: weeklyLayout)
        weeklyCollectionView.backgroundColor = .clear
        weeklyCollectionView.delegate = self
        weeklyCollectionView.dataSource = self
        weeklyCollectionView.register(WeeklyWeatherCell.self, forCellWithReuseIdentifier: "WeeklyWeatherCell")
        weeklyCollectionView.showsHorizontalScrollIndicator = false
        weeklyCollectionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(weeklyCollectionView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 15),
            backButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            backButton.widthAnchor.constraint(equalToConstant: 35),
            backButton.heightAnchor.constraint(equalToConstant: 35),
            
            toggleLocationButton.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 15),
            toggleLocationButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            toggleLocationButton.widthAnchor.constraint(equalToConstant: 100),
            toggleLocationButton.heightAnchor.constraint(equalToConstant: 36),
            
            locationLabel.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 60),
            locationLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            cityLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 10),
            cityLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            temperatureLabel.topAnchor.constraint(equalTo: cityLabel.bottomAnchor, constant: 25),
            temperatureLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            weatherIconView.centerYAnchor.constraint(equalTo: temperatureLabel.centerYAnchor),
            weatherIconView.trailingAnchor.constraint(equalTo: temperatureLabel.leadingAnchor, constant: -20),
            weatherIconView.widthAnchor.constraint(equalToConstant: 70),
            weatherIconView.heightAnchor.constraint(equalToConstant: 70),
            
            conditionLabel.topAnchor.constraint(equalTo: temperatureLabel.bottomAnchor, constant: 20),
            conditionLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            weatherTagLabel.topAnchor.constraint(equalTo: conditionLabel.bottomAnchor, constant: 10),
            weatherTagLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            weatherTagLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 20),
            weatherTagLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -20),
            
            // Updated additional details constraints
            additionalDetailsView.topAnchor.constraint(equalTo: weatherTagLabel.bottomAnchor, constant: 20),
            additionalDetailsView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            additionalDetailsView.widthAnchor.constraint(equalToConstant: 380),
            additionalDetailsView.heightAnchor.constraint(equalToConstant: 140), // Height for two rows
            
            // First row: Humidity and Wind (centered)
            // Humidity
            humidityIconView.topAnchor.constraint(equalTo: additionalDetailsView.topAnchor, constant: 10),
            humidityIconView.centerXAnchor.constraint(equalTo: additionalDetailsView.centerXAnchor, constant: -70), // Offset to left
            humidityIconView.widthAnchor.constraint(equalToConstant: 24),
            humidityIconView.heightAnchor.constraint(equalToConstant: 24),
            
            humidityLabel.topAnchor.constraint(equalTo: humidityIconView.bottomAnchor, constant: 8),
            humidityLabel.centerXAnchor.constraint(equalTo: humidityIconView.centerXAnchor),
            
            // Wind
            windIconView.topAnchor.constraint(equalTo: additionalDetailsView.topAnchor, constant: 10),
            windIconView.centerXAnchor.constraint(equalTo: additionalDetailsView.centerXAnchor, constant: 70), // Offset to right
            windIconView.widthAnchor.constraint(equalToConstant: 24),
            windIconView.heightAnchor.constraint(equalToConstant: 24),
            
            windLabel.topAnchor.constraint(equalTo: windIconView.bottomAnchor, constant: 8),
            windLabel.centerXAnchor.constraint(equalTo: windIconView.centerXAnchor),
            
            // Second row: Pressure and Visibility (centered)
            // Pressure
            pressureIconView.topAnchor.constraint(equalTo: humidityLabel.bottomAnchor, constant: 20),
            pressureIconView.centerXAnchor.constraint(equalTo: additionalDetailsView.centerXAnchor, constant: -70), // Offset to left
            pressureIconView.widthAnchor.constraint(equalToConstant: 24),
            pressureIconView.heightAnchor.constraint(equalToConstant: 24),
            
            pressureLabel.topAnchor.constraint(equalTo: pressureIconView.bottomAnchor, constant: 8),
            pressureLabel.centerXAnchor.constraint(equalTo: pressureIconView.centerXAnchor),
            
            // Visibility
            visibilityIconView.topAnchor.constraint(equalTo: windLabel.bottomAnchor, constant: 20),
            visibilityIconView.centerXAnchor.constraint(equalTo: additionalDetailsView.centerXAnchor, constant: 70), // Offset to right
            visibilityIconView.widthAnchor.constraint(equalToConstant: 24),
            visibilityIconView.heightAnchor.constraint(equalToConstant: 24),
            
            visibilityLabel.topAnchor.constraint(equalTo: visibilityIconView.bottomAnchor, constant: 8),
            visibilityLabel.centerXAnchor.constraint(equalTo: visibilityIconView.centerXAnchor),
            
            hourly24Label.topAnchor.constraint(equalTo: additionalDetailsView.bottomAnchor, constant: 35),
            hourly24Label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            
            hourly24CollectionView.topAnchor.constraint(equalTo: hourly24Label.bottomAnchor, constant: 10),
            hourly24CollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            hourly24CollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            hourly24CollectionView.heightAnchor.constraint(equalToConstant: 120),
            
            weeklyLabel.topAnchor.constraint(equalTo: hourly24CollectionView.bottomAnchor, constant: 25),
            weeklyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            
            weeklyCollectionView.topAnchor.constraint(equalTo: weeklyLabel.bottomAnchor, constant: 10),
            weeklyCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            weeklyCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            weeklyCollectionView.heightAnchor.constraint(equalToConstant: 140),
            
            contentView.bottomAnchor.constraint(greaterThanOrEqualTo: weeklyCollectionView.bottomAnchor, constant: 20)
        ])
    }
    
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
    
    // MARK: - Animations
    private func animateUIIn() {
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut, animations: {
            self.locationLabel.alpha = 1
            self.cityLabel.alpha = 1
        }, completion: nil)
        
        UIView.animate(withDuration: 0.8, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
            self.temperatureLabel.alpha = 1
            self.temperatureLabel.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        }) { _ in
            UIView.animate(withDuration: 0.3) {
                self.temperatureLabel.transform = .identity
            }
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.3, options: .curveEaseInOut, animations: {
            self.weatherIconView.alpha = 1
            self.conditionLabel.alpha = 1
            self.weatherTagLabel.alpha = 1
            self.additionalDetailsView.alpha = 1
            self.hourly24Label.alpha = 1
            self.weeklyLabel.alpha = 1
        }, completion: nil)
    }
    
    private func animateWeatherIcon(for condition: WeatherCondition) {
        weatherIconView.image = UIImage(systemName: condition.rawValue)
        weatherIconView.layer.removeAllAnimations()
        
        switch condition {
        case .sunny:
            UIView.animate(withDuration: 1.5, delay: 0, options: [.repeat, .autoreverse], animations: {
                self.weatherIconView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }, completion: nil)
            UIView.animate(withDuration: 10.0, delay: 0, options: [.repeat], animations: {
                self.weatherIconView.transform = CGAffineTransform(rotationAngle: .pi * 2)
            }, completion: nil)
            
        case .clearNight:
            UIView.animate(withDuration: 2.0, delay: 0, options: [.repeat, .autoreverse], animations: {
                self.weatherIconView.alpha = 0.7
                self.weatherIconView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }, completion: nil)
            UIView.animate(withDuration: 5.0, delay: 0, options: [.repeat], animations: {
                self.weatherIconView.transform = CGAffineTransform(rotationAngle: .pi / 4)
            }, completion: nil)
            
        case .cloudy:
            UIView.animateKeyframes(withDuration: 4.0, delay: 0, options: [.repeat], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                    self.weatherIconView.transform = CGAffineTransform(translationX: 15, y: -5)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                    self.weatherIconView.transform = CGAffineTransform(translationX: -15, y: 5)
                }
            }, completion: nil)
            
        case .rainy:
            UIView.animateKeyframes(withDuration: 1.5, delay: 0, options: [.repeat], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.33) {
                    self.weatherIconView.transform = CGAffineTransform(translationX: 0, y: 10)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.33, relativeDuration: 0.33) {
                    self.weatherIconView.transform = CGAffineTransform(translationX: 5, y: 0)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.66, relativeDuration: 0.33) {
                    self.weatherIconView.transform = CGAffineTransform(translationX: -5, y: 10)
                }
            }, completion: nil)
            
        case .storm:
            UIView.animate(withDuration: 0.3, delay: 0, options: [.repeat, .autoreverse], animations: {
                self.weatherIconView.alpha = 0.4
            }, completion: nil)
            UIView.animateKeyframes(withDuration: 1.0, delay: 0.5, options: [.repeat], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.25) {
                    self.weatherIconView.transform = CGAffineTransform(translationX: 5, y: 0)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.25) {
                    self.weatherIconView.transform = CGAffineTransform(translationX: -5, y: 0)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.25) {
                    self.weatherIconView.transform = CGAffineTransform(translationX: 0, y: 5)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.75, relativeDuration: 0.25) {
                    self.weatherIconView.transform = CGAffineTransform.identity
                }
            }, completion: nil)
            
        case .snow:
            UIView.animateKeyframes(withDuration: 3.0, delay: 0, options: [.repeat], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                    self.weatherIconView.transform = CGAffineTransform(translationX: 10, y: 15).rotated(by: .pi)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                    self.weatherIconView.transform = CGAffineTransform(translationX: -10, y: 0).rotated(by: -.pi)
                }
            }, completion: nil)
        }
    }
    
    // MARK: - Helper to Update City Labels
    private func updateCityLabels() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.isShowingSearchedCity, let cityState = self.lastSearchedCity {
                let components = cityState.components(separatedBy: ", ")
                self.cityLabel.text = components.count >= 1 ? components[0] : cityState
                self.locationLabel.text = components.count >= 2 ? components[1] : ""
            } else if let cityState = self.currentCityName {
                let components = cityState.components(separatedBy: ", ")
                self.cityLabel.text = components.count >= 1 ? components[0] : cityState
                self.locationLabel.text = components.count >= 2 ? components[1] : ""
            } else {
                self.cityLabel.text = "Unknown City"
                self.locationLabel.text = "Unknown Location"
            }
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
        if !isShowingSearchedCity {
            showLoadingIndicator()
            fetchWeatherData(for: location.coordinate)
        }
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self, let placemark = placemarks?.first, error == nil else { return }
            if let city = placemark.locality, let state = placemark.administrativeArea {
                self.currentCityName = "\(city), \(state)"
                if !self.isShowingSearchedCity {
                    self.updateCityLabels()
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error.localizedDescription)")
        hideLoadingIndicator()
    }
    
    // MARK: - Weather Fetching
    private func fetchWeatherData(for coordinate: CLLocationCoordinate2D) {
        WeatherService.shared.fetchWeather(for: coordinate) { [weak self] weatherData, error in
            guard let self = self else { return }
            if let weather = weatherData, error == nil {
                DispatchQueue.main.async {
                    if self.isShowingSearchedCity {
                        self.searchedLocationWeather = weather
                    } else {
                        self.currentLocationWeather = weather
                    }
                    self.updateUI(with: weather)
                }
            } else {
                print("Failed to fetch current weather: \(error?.localizedDescription ?? "Unknown error")")
                self.hideLoadingIndicator()
            }
        }
        
        WeatherService.shared.fetchHourlyForecast(for: coordinate) { [weak self] hourlyData, error in
            guard let self = self else { return }
            if let hourlyData = hourlyData, error == nil {
                DispatchQueue.main.async {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "ha"
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    self.hourly24ForecastData = hourlyData.enumerated().map { (index, data) in
                        HourlyForecast(
                            time: formatter.string(from: data.date).lowercased(),
                            temp: "\(Int(data.temperature))°",
                            condition: WeatherCondition.fromIcon(data.icon)
                        )
                    }
                    self.hourly24CollectionView.reloadData()
                    self.hideLoadingIndicator()
                }
            } else {
                print("Failed to fetch hourly forecast: \(error?.localizedDescription ?? "Unknown error")")
                self.hideLoadingIndicator()
            }
        }
        
        WeatherService.shared.fetchWeeklyForecast(for: coordinate) { [weak self] dailyData, error in
            guard let self = self else { return }
            if let dailyData = dailyData, error == nil {
                DispatchQueue.main.async {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "EEE"
                    self.weeklyForecastData = dailyData.map { data in
                        DailyForecast(
                            day: formatter.string(from: data.date),
                            lowTemp: "\(Int(data.temperature - 5))°",
                            highTemp: "\(Int(data.temperature))°",
                            condition: WeatherCondition.fromIcon(data.icon)
                        )
                    }
                    self.weeklyCollectionView.reloadData()
                    self.hideLoadingIndicator()
                }
            } else {
                print("Failed to fetch weekly forecast: \(error?.localizedDescription ?? "Unknown error")")
                self.hideLoadingIndicator()
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
                    self._cityName = "\(city), \(state)"
                    self.lastSearchedCity = self._cityName
                    self.updateCityLabels()
                }
                self.fetchWeatherData(for: coordinate)
            } else {
                print("Failed to geocode city: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    self.hideLoadingIndicator()
                }
            }
        }
    }
    
    private func updateUI(with weather: WeatherData) {
        temperatureLabel.text = "\(Int(weather.temperature))°"
        conditionLabel.text = weather.description.capitalized
        let condition = WeatherCondition.fromIcon(weather.icon)
        weatherTagLabel.text = condition.getWeatherTag()
        
        humidityLabel.text = "\(weather.humidity)%"
        windLabel.text = "\(weather.windSpeed) km/h"
        pressureLabel.text = "\(weather.pressure) hPa"
        visibilityLabel.text = "\(weather.visibility / 1000) km"
        
        applyBackgroundGradient(for: weather.icon)
        animateWeatherIcon(for: condition)
        animateUIIn()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
        toggleLocationButton.layer.sublayers?.first?.frame = toggleLocationButton.bounds
    }
    
    private func applyBackgroundGradient(for icon: String) {
        let textColor: UIColor
        switch icon {
        case "01d":
            gradientLayer.colors = [UIColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 1.0).cgColor, UIColor(red: 0.9, green: 0.6, blue: 0.2, alpha: 1.0).cgColor]
            textColor = .white
        case "01n":
            gradientLayer.colors = [UIColor(red: 0.1, green: 0.1, blue: 0.4, alpha: 1.0).cgColor, UIColor(red: 0.0, green: 0.0, blue: 0.2, alpha: 1.0).cgColor]
            textColor = .white
        case "02d", "03d", "04d":
            gradientLayer.colors = [UIColor(red: 0.7, green: 0.8, blue: 0.9, alpha: 1.0).cgColor, UIColor(red: 0.5, green: 0.6, blue: 0.8, alpha: 1.0).cgColor]
            textColor = .black
        case "02n", "03n", "04n":
            gradientLayer.colors = [UIColor(red: 0.2, green: 0.2, blue: 0.5, alpha: 1.0).cgColor, UIColor(red: 0.1, green: 0.1, blue: 0.3, alpha: 1.0).cgColor]
            textColor = .white
        case "09d", "10d":
            gradientLayer.colors = [UIColor(red: 0.5, green: 0.7, blue: 0.9, alpha: 1.0).cgColor, UIColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 1.0).cgColor]
            textColor = .black
        case "09n", "10n":
            gradientLayer.colors = [UIColor(red: 0.2, green: 0.3, blue: 0.6, alpha: 1.0).cgColor, UIColor(red: 0.1, green: 0.2, blue: 0.4, alpha: 1.0).cgColor]
            textColor = .white
        case "11d", "11n":
            gradientLayer.colors = [UIColor(red: 0.4, green: 0.4, blue: 0.5, alpha: 1.0).cgColor, UIColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1.0).cgColor]
            textColor = .white
        case "13d":
            gradientLayer.colors = [UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0).cgColor, UIColor(red: 0.7, green: 0.8, blue: 0.9, alpha: 1.0).cgColor]
            textColor = .black
        case "13n":
            gradientLayer.colors = [UIColor(red: 0.6, green: 0.7, blue: 0.9, alpha: 1.0).cgColor, UIColor(red: 0.4, green: 0.5, blue: 0.7, alpha: 1.0).cgColor]
            textColor = .white
        case "50d", "50n":
            gradientLayer.colors = [UIColor(red: 0.7, green: 0.7, blue: 0.8, alpha: 1.0).cgColor, UIColor(red: 0.5, green: 0.5, blue: 0.6, alpha: 1.0).cgColor]
            textColor = .white
        default:
            gradientLayer.colors = [UIColor.systemGray.cgColor, UIColor.darkGray.cgColor]
            textColor = .white
        }
        
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.7)
        view.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
        view.layer.insertSublayer(gradientLayer, at: 0)
        CATransaction.commit()
        
        temperatureLabel.textColor = textColor
        conditionLabel.textColor = textColor
        weatherTagLabel.textColor = textColor
        cityLabel.textColor = textColor
        backButton.tintColor = textColor
        toggleLocationButton.tintColor = textColor
        locationLabel.textColor = textColor
        hourly24Label.textColor = textColor
        weeklyLabel.textColor = textColor
        
        humidityLabel.textColor = textColor
        humidityIconView.tintColor = textColor
        windLabel.textColor = textColor
        windIconView.tintColor = textColor
        pressureLabel.textColor = textColor
        pressureIconView.tintColor = textColor
        visibilityLabel.textColor = textColor
        visibilityIconView.tintColor = textColor
    }
    
    @objc private func backButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func toggleLocationTapped() {
        UIView.animate(withDuration: 0.2, delay: 0.2, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: [], animations: {
            self.toggleLocationButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                self.toggleLocationButton.transform = .identity
            }
        }
        
        if toggleLocationButton.title(for: .normal) == "Current" {
            if let searchedCity = lastSearchedCity {
                toggleLocationButton.setTitle("Searched", for: .normal)
                isShowingSearchedCity = true
                updateCityLabels()
                showLoadingIndicator()
                fetchWeatherForCity(searchedCity)
            }
        } else {
            toggleLocationButton.setTitle("Current", for: .normal)
            isShowingSearchedCity = false
            updateCityLabels()
            if let coordinate = currentCoordinate {
                showLoadingIndicator()
                fetchWeatherData(for: coordinate)
            } else {
                showLoadingIndicator()
                requestLocation()
            }
        }
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension DetailedViews: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == hourly24CollectionView {
            return hourly24ForecastData.count
        } else {
            return weeklyForecastData.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == hourly24CollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WeatherCell", for: indexPath) as! WeatherCell
            let data = hourly24ForecastData[indexPath.item]
            cell.configure(with: data)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WeeklyWeatherCell", for: indexPath) as! WeeklyWeatherCell
            let data = weeklyForecastData[indexPath.item]
            cell.configure(with: data)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        cell.alpha = 0
        UIView.animate(withDuration: 0.5, delay: 0.05 * Double(indexPath.item), options: .curveEaseInOut, animations: {
            cell.alpha = 1
        }, completion: nil)
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
        [timeLabel, weatherIcon, tempLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        timeLabel.font = .systemFont(ofSize: 14, weight: .medium)
        timeLabel.textColor = .white
        timeLabel.textAlignment = .center
        
        weatherIcon.contentMode = .scaleAspectFit
        weatherIcon.tintColor = .white
        weatherIcon.layer.shadowColor = UIColor.white.cgColor
        weatherIcon.layer.shadowOpacity = 0.6
        weatherIcon.layer.shadowRadius = 3
        weatherIcon.layer.shadowOffset = .zero
        
        tempLabel.font = .systemFont(ofSize: 16, weight: .medium)
        tempLabel.textColor = .white
        tempLabel.textAlignment = .center
        
        NSLayoutConstraint.activate([
            timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            timeLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            weatherIcon.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 12),
            weatherIcon.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            weatherIcon.widthAnchor.constraint(equalToConstant: 35),
            weatherIcon.heightAnchor.constraint(equalToConstant: 35),
            
            tempLabel.topAnchor.constraint(equalTo: weatherIcon.bottomAnchor, constant: 12),
            tempLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }
    
    func configure(with data: HourlyForecast) {
        timeLabel.text = data.time
        tempLabel.text = data.temp
        weatherIcon.image = UIImage(systemName: data.condition.rawValue)
        animateIcon(for: data.condition)
    }
    
    private func animateIcon(for condition: WeatherCondition) {
        weatherIcon.layer.removeAllAnimations()
        switch condition {
        case .sunny:
            UIView.animate(withDuration: 1.5, delay: 0, options: [.repeat, .autoreverse], animations: {
                self.weatherIcon.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }, completion: nil)
            UIView.animate(withDuration: 10.0, delay: 0, options: [.repeat], animations: {
                self.weatherIcon.transform = CGAffineTransform(rotationAngle: .pi * 2)
            }, completion: nil)
            
        case .clearNight:
            UIView.animate(withDuration: 2.0, delay: 0, options: [.repeat, .autoreverse], animations: {
                self.weatherIcon.alpha = 0.7
                self.weatherIcon.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }, completion: nil)
            
        case .cloudy:
            UIView.animateKeyframes(withDuration: 4.0, delay: 0, options: [.repeat], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                    self.weatherIcon.transform = CGAffineTransform(translationX: 10, y: -3)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                    self.weatherIcon.transform = CGAffineTransform(translationX: -10, y: 3)
                }
            }, completion: nil)
            
        case .rainy:
            UIView.animateKeyframes(withDuration: 1.5, delay: 0, options: [.repeat], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.33) {
                    self.weatherIcon.transform = CGAffineTransform(translationX: 0, y: 8)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.33, relativeDuration: 0.33) {
                    self.weatherIcon.transform = CGAffineTransform(translationX: 3, y: 0)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.66, relativeDuration: 0.33) {
                    self.weatherIcon.transform = CGAffineTransform(translationX: -3, y: 8)
                }
            }, completion: nil)
            
        case .storm:
            UIView.animate(withDuration: 0.3, delay: 0, options: [.repeat, .autoreverse], animations: {
                self.weatherIcon.alpha = 0.5
            }, completion: nil)
            UIView.animateKeyframes(withDuration: 1.0, delay: 0.5, options: [.repeat], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.25) {
                    self.weatherIcon.transform = CGAffineTransform(translationX: 3, y: 0)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.25) {
                    self.weatherIcon.transform = CGAffineTransform(translationX: -3, y: 0)
                }
            }, completion: nil)
            
        case .snow:
            UIView.animateKeyframes(withDuration: 3.0, delay: 0, options: [.repeat], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                    self.weatherIcon.transform = CGAffineTransform(translationX: 8, y: 10).rotated(by: .pi)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                    self.weatherIcon.transform = CGAffineTransform(translationX: -8, y: 0).rotated(by: -.pi)
                }
            }, completion: nil)
        }
    }
}

// MARK: - WeeklyWeatherCell
class WeeklyWeatherCell: UICollectionViewCell {
    private let dayLabel = UILabel()
    private let weatherIcon = UIImageView()
    private let tempLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCellUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCellUI() {
        backgroundColor = .clear
        [dayLabel, weatherIcon, tempLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        dayLabel.font = .systemFont(ofSize: 14, weight: .medium)
        dayLabel.textColor = .white
        dayLabel.textAlignment = .center
        
        weatherIcon.contentMode = .scaleAspectFit
        weatherIcon.tintColor = .white
        weatherIcon.layer.shadowColor = UIColor.white.cgColor
        weatherIcon.layer.shadowOpacity = 0.6
        weatherIcon.layer.shadowRadius = 3
        weatherIcon.layer.shadowOffset = .zero
        
        tempLabel.font = .systemFont(ofSize: 16, weight: .medium)
        tempLabel.textColor = .white
        tempLabel.textAlignment = .center
        
        NSLayoutConstraint.activate([
            dayLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            dayLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            weatherIcon.topAnchor.constraint(equalTo: dayLabel.bottomAnchor, constant: 12),
            weatherIcon.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            weatherIcon.widthAnchor.constraint(equalToConstant: 35),
            weatherIcon.heightAnchor.constraint(equalToConstant: 35),
            
            tempLabel.topAnchor.constraint(equalTo: weatherIcon.bottomAnchor, constant: 12),
            tempLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }
    
    func configure(with data: DailyForecast) {
        dayLabel.text = data.day
        tempLabel.text = "\(data.lowTemp) - \(data.highTemp)"
        weatherIcon.image = UIImage(systemName: data.condition.rawValue)
        animateIcon(for: data.condition)
    }
    
    private func animateIcon(for condition: WeatherCondition) {
        weatherIcon.layer.removeAllAnimations()
        switch condition {
        case .sunny:
            UIView.animate(withDuration: 1.5, delay: 0, options: [.repeat, .autoreverse], animations: {
                self.weatherIcon.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }, completion: nil)
            UIView.animate(withDuration: 10.0, delay: 0, options: [.repeat], animations: {
                self.weatherIcon.transform = CGAffineTransform(rotationAngle: .pi * 2)
            }, completion: nil)
            
        case .clearNight:
            UIView.animate(withDuration: 2.0, delay: 0, options: [.repeat, .autoreverse], animations: {
                self.weatherIcon.alpha = 0.7
                self.weatherIcon.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }, completion: nil)
            
        case .cloudy:
            UIView.animateKeyframes(withDuration: 4.0, delay: 0, options: [.repeat], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                    self.weatherIcon.transform = CGAffineTransform(translationX: 10, y: -3)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                    self.weatherIcon.transform = CGAffineTransform(translationX: -10, y: 3)
                }
            }, completion: nil)
            
        case .rainy:
            UIView.animateKeyframes(withDuration: 1.5, delay: 0, options: [.repeat], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.33) {
                    self.weatherIcon.transform = CGAffineTransform(translationX: 0, y: 8)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.33, relativeDuration: 0.33) {
                    self.weatherIcon.transform = CGAffineTransform(translationX: 3, y: 0)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.66, relativeDuration: 0.33) {
                    self.weatherIcon.transform = CGAffineTransform(translationX: -3, y: 8)
                }
            }, completion: nil)
            
        case .storm:
            UIView.animate(withDuration: 0.3, delay: 0, options: [.repeat, .autoreverse], animations: {
                self.weatherIcon.alpha = 0.5
            }, completion: nil)
            UIView.animateKeyframes(withDuration: 1.0, delay: 0.5, options: [.repeat], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.25) {
                    self.weatherIcon.transform = CGAffineTransform(translationX: 3, y: 0)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.25) {
                    self.weatherIcon.transform = CGAffineTransform(translationX: -3, y: 0)
                }
            }, completion: nil)
            
        case .snow:
            UIView.animateKeyframes(withDuration: 3.0, delay: 0, options: [.repeat], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                    self.weatherIcon.transform = CGAffineTransform(translationX: 8, y: 10).rotated(by: .pi)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                    self.weatherIcon.transform = CGAffineTransform(translationX: -8, y: 0).rotated(by: -.pi)
                }
            }, completion: nil)
        }
    }
}
