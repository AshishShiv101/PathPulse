import UIKit
import MapKit
import CoreLocation
class MapPage: UIViewController, CLLocationManagerDelegate, UISearchBarDelegate, MKMapViewDelegate,SOSOverlayViewDelegate {
    func didTapAddContact() {
           let editContactVC = EditContactViewController()
           navigationController?.pushViewController(editContactVC, animated: true)
       }
    let locationManager = CLLocationManager()
    let mapView = MKMapView()
    private let bottomSheetView = UIView()
    var weatherInfoView: UIView?
    let searchBar = UISearchBar()
    private var bottomSheetTopConstraint: NSLayoutConstraint!
    var startLocationCoordinate: CLLocationCoordinate2D?
    var destinationCoordinate: CLLocationCoordinate2D?
    private let bottomSheetCollapsedHeight: CGFloat = 135
    private let bottomSheetMediumHeight: CGFloat = 300
    private let bottomSheetExpandedHeight: CGFloat = 800
    let searchButton = UIButton()
    let directionButton = UIButton()
    var previousContentViews: [UIView] = []
    let sosButton = UIButton()
    private let sosOverlayView = SOSOverlayView()
    let weeklyButton = UIButton()
    let hourlyButton = UIButton()
    private let hourlyView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#333333")
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.clipsToBounds = true
        view.isHidden = true
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        view.addSubview(scrollView)

        let containerView = UIStackView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.axis = .horizontal
        containerView.spacing = 16
        containerView.alignment = .center
        containerView.distribution = .fill
        scrollView.addSubview(containerView)

        for i in 0..<9 {
            let dataView = UIView()
            dataView.translatesAutoresizingMaskIntoConstraints = false
            dataView.backgroundColor = UIColor(hex: "#222222")
            dataView.layer.cornerRadius = 16
            dataView.layer.shadowColor = UIColor.black.cgColor
            dataView.layer.shadowOpacity = 0.3
            dataView.layer.shadowOffset = CGSize(width: 0, height: 4)
            dataView.layer.shadowRadius = 8
            dataView.widthAnchor.constraint(equalToConstant: 120).isActive = true
            dataView.heightAnchor.constraint(equalToConstant: 150).isActive = true

            let stackView = UIStackView()
            stackView.axis = .vertical
            stackView.spacing = 8
            stackView.alignment = .center
            stackView.distribution = .equalSpacing
            stackView.translatesAutoresizingMaskIntoConstraints = false
            
            let weatherIcon = UIImageView()
            weatherIcon.image = UIImage(systemName: "cloud.sun.fill")
            weatherIcon.tintColor = .systemYellow
            weatherIcon.translatesAutoresizingMaskIntoConstraints = false
            weatherIcon.contentMode = .scaleAspectFit
            weatherIcon.heightAnchor.constraint(equalToConstant: 50).isActive = true
            weatherIcon.widthAnchor.constraint(equalToConstant: 50).isActive = true

            let timeLabel = UILabel()
            timeLabel.text = "\(i + 1) PM"
            timeLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            timeLabel.textColor = .white
            timeLabel.textAlignment = .center
            timeLabel.translatesAutoresizingMaskIntoConstraints = false

            let temperatureLabel = UILabel()
            temperatureLabel.text = "\(20 + i)°C"
            temperatureLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
            temperatureLabel.textColor = .white
            temperatureLabel.textAlignment = .center
            temperatureLabel.translatesAutoresizingMaskIntoConstraints = false

            stackView.addArrangedSubview(weatherIcon)
            stackView.addArrangedSubview(timeLabel)
            stackView.addArrangedSubview(temperatureLabel)

            dataView.addSubview(stackView)

            NSLayoutConstraint.activate([
                stackView.centerXAnchor.constraint(equalTo: dataView.centerXAnchor),
                stackView.centerYAnchor.constraint(equalTo: dataView.centerYAnchor)
            ])

            containerView.addArrangedSubview(dataView)
        }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),

            containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            containerView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])

        view.heightAnchor.constraint(equalToConstant: 300).isActive = true

        return view
    }()

    private let weeklyView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#333333")
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.clipsToBounds = true
        view.isHidden = true

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.isPagingEnabled = false
        view.addSubview(scrollView)

        let containerView = UIStackView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.axis = .horizontal
        containerView.spacing = 16
        containerView.alignment = .center
        containerView.distribution = .fill
        scrollView.addSubview(containerView)

        let daysOfWeek = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

        for i in 0..<7 {
            let dataView = UIView()
            dataView.translatesAutoresizingMaskIntoConstraints = false
            dataView.backgroundColor =  UIColor(hex: "#222222")
            dataView.layer.cornerRadius = 16
            dataView.layer.shadowColor = UIColor.black.cgColor
            dataView.layer.shadowOpacity = 0.3
            dataView.layer.shadowOffset = CGSize(width: 0, height: 4)
            dataView.layer.shadowRadius = 8
            dataView.widthAnchor.constraint(equalToConstant: 120).isActive = true
            dataView.heightAnchor.constraint(equalToConstant: 150).isActive = true

            let stackView = UIStackView()
            stackView.axis = .vertical
            stackView.spacing = 8
            stackView.alignment = .center
            stackView.distribution = .equalSpacing
            stackView.translatesAutoresizingMaskIntoConstraints = false

            let weatherIcon = UIImageView()
            weatherIcon.image = UIImage(systemName: "cloud.sun.fill") 
            weatherIcon.tintColor = .systemYellow
            weatherIcon.translatesAutoresizingMaskIntoConstraints = false
            weatherIcon.contentMode = .scaleAspectFit
            weatherIcon.heightAnchor.constraint(equalToConstant: 50).isActive = true
            weatherIcon.widthAnchor.constraint(equalToConstant: 50).isActive = true

            let dayLabel = UILabel()
            dayLabel.text = daysOfWeek[i] // Display the day of the week
            dayLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            dayLabel.textColor = .white
            dayLabel.textAlignment = .center
            dayLabel.translatesAutoresizingMaskIntoConstraints = false

            let temperatureLabel = UILabel()
            temperatureLabel.text = "\(20 + i)°C" // Example temperature, replace with actual data
            temperatureLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
            temperatureLabel.textColor = .white
            temperatureLabel.textAlignment = .center
            temperatureLabel.translatesAutoresizingMaskIntoConstraints = false

            stackView.addArrangedSubview(weatherIcon)
            stackView.addArrangedSubview(dayLabel)
            stackView.addArrangedSubview(temperatureLabel)

            dataView.addSubview(stackView)

            NSLayoutConstraint.activate([
                stackView.centerXAnchor.constraint(equalTo: dataView.centerXAnchor),
                stackView.centerYAnchor.constraint(equalTo: dataView.centerYAnchor)
            ])

            containerView.addArrangedSubview(dataView)
        }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),

            containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            containerView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])

        return view
    }()    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        setupBottomSheet()
        setupSOSButton()
        setupSOSOverlay()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        searchBar.delegate = self
        mapView.showsUserLocation = true
        mapView.delegate = self
        setupLocationButton()
        hourlyButton.backgroundColor = UIColor(hex: "#40cbd8")
        hourlyButton.setTitleColor(.white, for: .normal)
        weeklyButton.backgroundColor = .white
        weeklyButton.setTitleColor(UIColor(hex: "#333333"), for: .normal)
        hourlyView.isHidden = false
        weeklyView.isHidden = true
        view.bringSubviewToFront(bottomSheetView)
        sosOverlayView.translatesAutoresizingMaskIntoConstraints = false
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        mapView.addGestureRecognizer(longPressGesture)
    }
    private let weatherView: UIView = {
            let view = UIView()
            view.backgroundColor = UIColor(hex: "#222222")
            view.layer.cornerRadius = 20
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
            label.textColor = UIColor(hex:"40CBD8")
            label.textAlignment = .center
            label.text = "Humidity: --%"
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
        private let windSpeedLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            label.textColor = UIColor(hex:"40CBD8")
            label.textAlignment = .center
            label.text = "Wind: -- m/s"
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
    @objc private func locationButtonTapped() {
            if let userLocation = locationManager.location {
                let coordinate = userLocation.coordinate
                let region = MKCoordinateRegion(
                    center: coordinate,
                    latitudinalMeters: 1000,
                    longitudinalMeters: 1000
                )
                mapView.setRegion(region, animated: true)
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
        sosOverlayView.delegate = self
        view.addSubview(sosOverlayView)
        sosOverlayView.addContactIcon(iconName: "cross.circle.fill", label: "Ambulance", number: "102")
        sosOverlayView.addContactIcon(iconName: "shield.fill", label: "Police", number: "100")
        sosOverlayView.addContactIcon(iconName: "figure.stand.dress", label: "Women", number: "1091")
        sosOverlayView.layer.zPosition = 0
        NSLayoutConstraint.activate([
            sosOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            sosOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            sosOverlayView.topAnchor.constraint(equalTo: view.topAnchor, constant: 170),
            sosOverlayView.heightAnchor.constraint(equalToConstant: 200)
        ])
        func didTapAddContact() {
            let editContactVC = EditContactViewController()
            navigationController?.pushViewController(editContactVC, animated: true)
        }
    }
    func updateWeatherUI(with weatherData: WeatherData) {
        self.temperatureLabel.text = "\(Int(weatherData.temperature))°C"
        self.humidityLabel.text = "Humidity: \(weatherData.humidity)%"
        self.windSpeedLabel.text = "Wind: \(weatherData.windSpeed) m/s"
        if let iconUrl = URL(string: "https://openweathermap.org/img/wn/\(weatherData.icon)@2x.png"),
           let data = try? Data(contentsOf: iconUrl) {
            self.weatherIcon.image = UIImage(data: data)
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
        
        
        mapView.mapType = .standard // Traffic is best displayed on the standard map type
        mapView.showsTraffic = true
        mapView.showsUserLocation = true // Optional: Show the user's location if relevant
    }

    private func setupBottomSheet() {
        bottomSheetView.backgroundColor = UIColor(hex: "#151515").withAlphaComponent(0.85)
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
        searchBar.placeholder = "Search for locations..."
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
            searchBar.leadingAnchor.constraint(equalTo: bottomSheetView.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: bottomSheetView.trailingAnchor, constant: -16),
            searchBar.heightAnchor.constraint(equalToConstant: 44)
        ])
        bottomSheetView.addSubview(weatherView)
        weatherView.addSubview(weatherIcon)
        weatherView.addSubview(temperatureLabel)
        weatherView.addSubview(humidityLabel)
        weatherView.addSubview(windSpeedLabel)
        NSLayoutConstraint.activate([
            weatherView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 20),
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
            windSpeedLabel.trailingAnchor.constraint(equalTo: weatherView.trailingAnchor, constant: -20)
        ])

        let distanceView = UIView()
        distanceView.translatesAutoresizingMaskIntoConstraints = false
        distanceView.backgroundColor = .white
        distanceView.layer.cornerRadius = 10
        distanceView.layer.borderWidth = 1
        distanceView.layer.borderColor = UIColor.gray.cgColor
        bottomSheetView.addSubview(distanceView)

        hourlyButton.translatesAutoresizingMaskIntoConstraints = false
        hourlyButton.setTitle("Hourly", for: .normal)
        hourlyButton.setTitleColor(UIColor(hex: "#333333"), for: .normal)
        hourlyButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        hourlyButton.backgroundColor = UIColor.white
        hourlyButton.layer.cornerRadius = 10
        hourlyButton.layer.borderWidth = 1
        hourlyButton.layer.borderColor = UIColor(hex: "#40cbd8").cgColor
        hourlyButton.addTarget(self, action: #selector(hourlyButtonTapped), for: .touchUpInside)
        bottomSheetView.addSubview(hourlyButton)
        
        weeklyButton.translatesAutoresizingMaskIntoConstraints = false
        weeklyButton.setTitle("Weekly", for: .normal)
        weeklyButton.setTitleColor(UIColor(hex: "#333333"), for: .normal)
        weeklyButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        weeklyButton.backgroundColor = UIColor.white
        weeklyButton.layer.cornerRadius = 10
        weeklyButton.layer.borderWidth = 1
        weeklyButton.layer.borderColor = UIColor(hex: "#40cbd8").cgColor
        weeklyButton.addTarget(self, action: #selector(weeklyButtonTapped), for: .touchUpInside)
        bottomSheetView.addSubview(weeklyButton)
        
        NSLayoutConstraint.activate([
            hourlyButton.heightAnchor.constraint(equalToConstant: 44),
            hourlyButton.topAnchor.constraint(equalTo: weatherView.bottomAnchor, constant: 60),
            hourlyButton.leadingAnchor.constraint(equalTo: bottomSheetView.leadingAnchor, constant: 16),
            hourlyButton.trailingAnchor.constraint(equalTo: bottomSheetView.centerXAnchor, constant: -8),
            
            weeklyButton.heightAnchor.constraint(equalToConstant: 44),
            weeklyButton.topAnchor.constraint(equalTo: weatherView.bottomAnchor, constant: 60),
            weeklyButton.leadingAnchor.constraint(equalTo: bottomSheetView.centerXAnchor, constant: 8),
            weeklyButton.trailingAnchor.constraint(equalTo: bottomSheetView.trailingAnchor, constant: -16)
        ])
        hourlyView.translatesAutoresizingMaskIntoConstraints = false
        bottomSheetView.addSubview(hourlyView)
        NSLayoutConstraint.activate([
            hourlyView.topAnchor.constraint(equalTo: hourlyButton.bottomAnchor, constant: 20),
            hourlyView.leadingAnchor.constraint(equalTo: bottomSheetView.leadingAnchor, constant: 16),
            hourlyView.trailingAnchor.constraint(equalTo: bottomSheetView.trailingAnchor, constant: -16),
            hourlyView.heightAnchor.constraint(equalToConstant: 170)
        ])
        weeklyView.translatesAutoresizingMaskIntoConstraints = false
        bottomSheetView.addSubview(weeklyView)
        NSLayoutConstraint.activate([
            weeklyView.topAnchor.constraint(equalTo: weeklyButton.bottomAnchor, constant: 20),
            weeklyView.leadingAnchor.constraint(equalTo: bottomSheetView.leadingAnchor, constant: 16),
            weeklyView.trailingAnchor.constraint(equalTo: bottomSheetView.trailingAnchor, constant: -16),
            weeklyView.heightAnchor.constraint(equalToConstant: 170)
        ])

        
        let showMoreButton = UIButton()
        showMoreButton.translatesAutoresizingMaskIntoConstraints = false
        showMoreButton.setTitle("News", for: .normal)
        showMoreButton.setTitleColor(UIColor(hex: "#333333"), for: .normal)
        showMoreButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        showMoreButton.backgroundColor = UIColor(hex: "#40cbd8")
        showMoreButton.layer.cornerRadius = 10
        showMoreButton.clipsToBounds = true
        showMoreButton.addTarget(self, action: #selector(showMoreButtonTapped), for: .touchUpInside)
        bottomSheetView.addSubview(showMoreButton)
        
        NSLayoutConstraint.activate([
            showMoreButton.heightAnchor.constraint(equalToConstant: 44),
            showMoreButton.topAnchor.constraint(equalTo: weeklyButton.bottomAnchor, constant: 220),
            showMoreButton.widthAnchor.constraint(equalToConstant: 200),
            showMoreButton.centerXAnchor.constraint(equalTo: bottomSheetView.centerXAnchor)
        ])
    }
    @objc private func hourlyButtonTapped() {
        hourlyButton.backgroundColor = UIColor(hex: "#40cbd8")
        hourlyButton.setTitleColor(.white, for: .normal)
        
        weeklyButton.backgroundColor = .white
        weeklyButton.setTitleColor(UIColor(hex: "#333333"), for: .normal)
        
        hourlyView.isHidden = false
        weeklyView.isHidden = true
    }

    @objc private func weeklyButtonTapped() {
        weeklyButton.backgroundColor = UIColor(hex: "#40cbd8")
        weeklyButton.setTitleColor(.white, for: .normal)
        
        hourlyButton.backgroundColor = .white
        hourlyButton.setTitleColor(UIColor(hex: "#333333"), for: .normal)
        
        weeklyView.isHidden = false
        hourlyView.isHidden = true
    }

    @objc private func showMoreButtonTapped() {
        bottomSheetView.subviews.forEach { $0.removeFromSuperview() }
        let newContentPage = NewsSheet()
        bottomSheetView.addSubview(newContentPage)
        NSLayoutConstraint.activate([
            newContentPage.topAnchor.constraint(equalTo: bottomSheetView.topAnchor),
            newContentPage.leadingAnchor.constraint(equalTo: bottomSheetView.leadingAnchor),
            newContentPage.trailingAnchor.constraint(equalTo: bottomSheetView.trailingAnchor),
            newContentPage.bottomAnchor.constraint(equalTo: bottomSheetView.bottomAnchor)
        ])

        newContentPage.backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }
    @objc private func backButtonTapped(){
        bottomSheetView.subviews.forEach { $0.removeFromSuperview() }
        addContentToBottomSheet()
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
  
            fetchWeather(for: coordinate)
        }
        
        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                locationManager.startUpdatingLocation()
            } else {
                print("Location permission denied.")
            }
        }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let cityName = searchBar.text, !cityName.isEmpty else {
            return
        }
        CitySearchHelper.searchForCity(city: cityName, mapView: mapView, locationManager: locationManager) {
            [weak self] (weatherData, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            if let weatherData = weatherData {
            
                DispatchQueue.main.async {
                    self?.updateWeatherUI(with: weatherData)
                }
            }
        }
        searchBar.resignFirstResponder()
    }
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .blue
            renderer.lineWidth = 4
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
                   DispatchQueue.main.async {
                       if let weatherData = weatherData {
                           self?.updateWeatherInfoView(weatherData)
                       } else {
                           self?.updateWeatherInfoViewWithError()
                       }
                   }
               }
           }
       }

    private func createWeatherInfoView(at location: CGPoint) -> UIView {
        let weatherView = UIView()
        weatherView.backgroundColor = UIColor(hex: "#222222") // Background color
        weatherView.layer.cornerRadius = 12
        weatherView.layer.shadowColor = UIColor.black.cgColor
        weatherView.layer.shadowOpacity = 0.2
        weatherView.layer.shadowOffset = CGSize(width: 0, height: 4)
        weatherView.layer.shadowRadius = 6
        weatherView.frame = CGRect(x: location.x - 110, y: location.y - 100, width: 220, height: 180) // Increased height for better spacing
        
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("×", for: .normal)
        closeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.frame = CGRect(x: weatherView.frame.width - 30, y: 10, width: 20, height: 20)
        closeButton.addTarget(self, action: #selector(dismissWeatherInfoView), for: .touchUpInside)
        weatherView.addSubview(closeButton)
        
        let weatherIcon = UIImageView()
        weatherIcon.frame = CGRect(x: (weatherView.frame.width - 80) / 2, y: 90, width: 150, height: 150) // Increased size to 80x80
        weatherIcon.contentMode = .scaleAspectFit
        weatherIcon.tintColor = .white
        weatherView.addSubview(weatherIcon)
        
        let titleLabel = UILabel()
        titleLabel.text = "Fetching weather..."
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .white // Text color set to white
        titleLabel.frame = CGRect(x: 10, y: 110, width: weatherView.frame.width - 20, height: 20) // Adjusted position
        weatherView.addSubview(titleLabel)
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = ""
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textAlignment = .center
        descriptionLabel.textColor = .white // Text color set to white
        descriptionLabel.frame = CGRect(x: 10, y: 135, width: weatherView.frame.width - 20, height: 20) // Adjusted position
        weatherView.addSubview(descriptionLabel)
        
        weatherInfoView?.tag = 1000
        
        return weatherView
    }


    @objc private func dismissWeatherInfoView() {
        weatherInfoView?.removeFromSuperview()
    }
    private func updateWeatherInfoView(_ weatherData: WeatherData) {
        guard let weatherInfoView = weatherInfoView else { return }

        // Update the temperature label
        if let titleLabel = weatherInfoView.subviews.first(where: { $0 is UILabel }) as? UILabel {
            titleLabel.text = "Temp: \(weatherData.temperature)°C"
        }

        // Update the description label
        if let descriptionLabel = weatherInfoView.subviews.last(where: { $0 is UILabel }) as? UILabel {
            descriptionLabel.text = weatherData.description.capitalized
        }

        // Add or update the weather icon
        let iconTag = 101 // Unique tag for the image view
        if let iconImageView = weatherInfoView.viewWithTag(iconTag) as? UIImageView {
            // If the image view exists, update its image
            updateWeatherIcon(iconImageView, with: weatherData.icon)
        } else {
            // If the image view doesn't exist, create and add it
            let iconImageView = UIImageView(frame: CGRect(x: weatherInfoView.bounds.width / 2 - 25, y: 10, width: 50, height: 50))
            iconImageView.contentMode = .scaleAspectFit
            iconImageView.tag = iconTag
            weatherInfoView.addSubview(iconImageView)

            // Fetch and set the image
            updateWeatherIcon(iconImageView, with: weatherData.icon)
        }
    }

    private func updateWeatherIcon(_ imageView: UIImageView, with iconCode: String) {
        let iconUrlString = "https://openweathermap.org/img/wn/\(iconCode)@2x.png"
        guard let iconUrl = URL(string: iconUrlString) else { return }

        // Fetch the image asynchronously
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: iconUrl), let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    imageView.image = image
                }
            }
        }
    }
    private func updateWeatherInfoViewWithError() {
        guard let weatherInfoView = weatherInfoView else { return }

        // Update the temperature label
        if let titleLabel = weatherInfoView.subviews.first(where: { $0 is UILabel }) as? UILabel {
            titleLabel.text = "Weather unavailable"
        }

        // Update the description label
        if let descriptionLabel = weatherInfoView.subviews.last(where: { $0 is UILabel }) as? UILabel {
            descriptionLabel.text = "Please try again later."
        }

        // Remove the weather icon if it exists
        let iconTag = 101
        if let iconImageView = weatherInfoView.viewWithTag(iconTag) as? UIImageView {
            iconImageView.removeFromSuperview()
        }
    }

       private func fetchWeather(for coordinate: CLLocationCoordinate2D, completion: @escaping (WeatherData?) -> Void) {
           WeatherService.shared.fetchWeather(for: coordinate) { weatherData, error in
               if let error = error {
                   print("Error fetching weather: \(error.localizedDescription)")
                   completion(nil)
               } else {
                   completion(weatherData)
               }
           }
       }
    @objc private func searchButtonTapped() {
        searchBar.becomeFirstResponder()
    }
}
