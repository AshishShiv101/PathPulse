import UIKit
import MapKit

class DirectionsBottomSheetViewController: UIViewController {
    
    // MARK: - Properties
    private let distance: String
    private let time: String
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#222222")
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Directions"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    // MARK: - Lifecycle
    init(distance: String, time: String) {
        self.distance = distance
        self.time = time
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLayout()
        updateUI()
    }
    
    // MARK: - Helper Methods
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
    
    private func updateUI() {
        distanceLabel.text = "Distance: \(distance)"
        timeLabel.text = "Time: \(time)"
    }
    
    // MARK: - Layout Setup
    private func setupLayout() {
        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(distanceLabel)
        containerView.addSubview(timeLabel)
        
        [containerView, titleLabel, distanceLabel, timeLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            distanceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            distanceLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            distanceLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            timeLabel.topAnchor.constraint(equalTo: distanceLabel.bottomAnchor, constant: 20),
            timeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            timeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20)
        ])
    }
}
