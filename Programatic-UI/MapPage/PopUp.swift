import UIKit

class WeatherDetailPopup: UIViewController {
    
    private let popupView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let weatherIconView: UIImageView = {
        let icon = UIImageView()
        icon.contentMode = .scaleAspectFit
        icon.tintColor = .black
        icon.translatesAutoresizingMaskIntoConstraints = false
        return icon
    }()
    
    private let tempLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 36, weight: .medium)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let precipitationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .regular)
        label.textColor = .black
        label.text = "Precipitation: --%"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let humidityLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .regular)
        label.textColor = .black
        label.text = "Humidity: --%"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let windLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .regular)
        label.textColor = .black
        label.text = "Wind: -- km/h"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .black
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        animatePopupIn()
    }
    
    private func setupUI() {
        view.addSubview(popupView)
        popupView.addSubview(timeLabel)
        popupView.addSubview(weatherIconView)
        popupView.addSubview(tempLabel)
        popupView.addSubview(precipitationLabel)
        popupView.addSubview(humidityLabel)
        popupView.addSubview(windLabel)
        popupView.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            popupView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            popupView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            popupView.widthAnchor.constraint(equalToConstant: 300),
            popupView.heightAnchor.constraint(equalToConstant: 350),
            
            closeButton.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 15),
            closeButton.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -15),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
            timeLabel.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 40),
            timeLabel.centerXAnchor.constraint(equalTo: popupView.centerXAnchor),
            
            weatherIconView.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 20),
            weatherIconView.centerXAnchor.constraint(equalTo: popupView.centerXAnchor),
            weatherIconView.widthAnchor.constraint(equalToConstant: 60),
            weatherIconView.heightAnchor.constraint(equalToConstant: 60),
            
            tempLabel.topAnchor.constraint(equalTo: weatherIconView.bottomAnchor, constant: 20),
            tempLabel.centerXAnchor.constraint(equalTo: popupView.centerXAnchor),
            
            precipitationLabel.topAnchor.constraint(equalTo: tempLabel.bottomAnchor, constant: 20),
            precipitationLabel.centerXAnchor.constraint(equalTo: popupView.centerXAnchor),
            
            humidityLabel.topAnchor.constraint(equalTo: precipitationLabel.bottomAnchor, constant: 15),
            humidityLabel.centerXAnchor.constraint(equalTo: popupView.centerXAnchor),
            
            windLabel.topAnchor.constraint(equalTo: humidityLabel.bottomAnchor, constant: 15),
            windLabel.centerXAnchor.constraint(equalTo: popupView.centerXAnchor)
        ])
    }
    
    private func animatePopupIn() {
        popupView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        popupView.alpha = 0
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
            self.popupView.transform = .identity
            self.popupView.alpha = 1
        }, completion: nil)
    }
    
    private func animatePopupOut(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.2, animations: {
            self.popupView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.popupView.alpha = 0
        }) { _ in
            completion()
        }
    }
    
    func configure(withHourly forecast: HourlyForecast) {
        timeLabel.text = forecast.time
        tempLabel.text = forecast.temp
        weatherIconView.image = UIImage(systemName: forecast.condition.rawValue)
        // Placeholder values for additional details (you'd fetch these from your weather API)
        precipitationLabel.text = "Precipitation: \(Int.random(in: 0...100))%"
        humidityLabel.text = "Humidity: \(Int.random(in: 20...90))%"
        windLabel.text = "Wind: \(Int.random(in: 5...30)) km/h"
    }
    
    func configure(withDaily forecast: DailyForecast) {
        timeLabel.text = forecast.day
        tempLabel.text = "\(forecast.lowTemp) - \(forecast.highTemp)"
        weatherIconView.image = UIImage(systemName: forecast.condition.rawValue)
        // Placeholder values for additional details (you'd fetch these from your weather API)
        precipitationLabel.text = "Precipitation: \(Int.random(in: 0...100))%"
        humidityLabel.text = "Humidity: \(Int.random(in: 20...90))%"
        windLabel.text = "Wind: \(Int.random(in: 5...30)) km/h"
    }
    
    @objc private func closeTapped() {
        animatePopupOut {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first, touch.view == view {
            animatePopupOut {
                self.dismiss(animated: false, completion: nil)
            }
        }
    }
}
