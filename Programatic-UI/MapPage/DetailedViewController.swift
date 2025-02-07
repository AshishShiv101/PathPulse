import UIKit
enum WeatherCondition: String {
    case sunny = "sun.max.fill"
    case cloudy = "cloud.fill"
    case rainy = "cloud.rain.fill"
    case storm = "cloud.bolt.rain.fill"
    case snow = "snow"
    
    var backgroundColors: (top: UIColor, bottom: UIColor) {
        switch self {
        case .storm:
            return (
                UIColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 1.0),
                UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0)
            )
        case .sunny:
            return (
                UIColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 1.0),
                UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
            )
        case .cloudy:
            return (
                UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0),
                UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
            )
        case .rainy:
            return (
                UIColor(red: 0.4, green: 0.4, blue: 0.5, alpha: 1.0),
                UIColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1.0)
            )
        case .snow:
            return (
                UIColor(red: 0.7, green: 0.7, blue: 0.8, alpha: 1.0),
                UIColor(red: 0.5, green: 0.5, blue: 0.6, alpha: 1.0)
            )
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

class DetailedViews: UIViewController {
    
    // MARK: - Properties
    private var currentCondition: WeatherCondition = .sunny {
        didSet {
            updateBackgroundColor()
        }
    }
    
    private var weatherCollectionView: UICollectionView!
    private var weeklyCollectionView: UICollectionView!
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var locationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.text = "LOCATION"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var cityName: String? {
           didSet {
               cityLabel.text = cityName
           }
       }

    private lazy var cityLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 36, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.text = "Chennai"
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
    
    // MARK: - Sample Data
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
    
    private let gradientLayer = CAGradientLayer()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        setupUI()
        setupWeatherCollectionView()
        setupWeeklyCollectionView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }
    
    // MARK: - Setup Methods
    private func setupGradientBackground() {
        gradientLayer.colors = [
            currentCondition.backgroundColors.top.cgColor,
            currentCondition.backgroundColors.bottom.cgColor
        ]
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func updateBackgroundColor() {
        let colors = currentCondition.backgroundColors
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.5)
        gradientLayer.colors = [
            colors.top.cgColor,
            colors.bottom.cgColor
        ]
        CATransaction.commit()
    }
    
    private func setupUI() {
        [backButton, locationLabel, cityLabel, temperatureLabel, conditionLabel, additionalDetailsLabel].forEach {
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
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
    
    // MARK: - Back Button Action
    @objc private func backButtonTapped() {
        dismiss(animated: true, completion: nil)
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
