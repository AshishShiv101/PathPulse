import UIKit
import CoreLocation

class BottomSheetViewController: UIViewController {
    
    // MARK: - Properties
    private var currentLocation: CLLocation?
    private var destinationLocation: CLLocation?
    private var selectedTransportMode: TransportMode = .car {
        didSet {
            calculateRouteInfo()
        }
    }
    
    enum TransportMode: Int {
        case car = 0
        case train = 1
    }
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#222222")
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: -3)
        view.layer.shadowRadius = 10
        return view
    }()
    
    private lazy var transportSegmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: [
            createSegmentItem(systemName: "car.fill", title: "Car"),
            createSegmentItem(systemName: "tram.fill", title: "Train")
        ])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        segmentedControl.selectedSegmentTintColor = UIColor(hex: "#40CBD8")
        
        // Set title text attributes for different states
        let normalTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 13, weight: .medium)
        ]
        let selectedTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold)
        ]
        
        segmentedControl.setTitleTextAttributes(normalTextAttributes, for: .normal)
        segmentedControl.setTitleTextAttributes(selectedTextAttributes, for: .selected)
        
        return segmentedControl
    }()
    
    private let routeInfoStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        return stack
    }()
    
    private let distanceContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let distanceSubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Total Distance"
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.7)
        return label
    }()
    
    private let timeInfoLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.7)
        label.textAlignment = .center
        return label
    }()
    
    private let startJourneyButton: UIButton = {
        let button = UIButton(configuration: .filled())
        button.configuration?.title = "Start Journey"
        button.configuration?.baseBackgroundColor = UIColor(hex: "#40CBD8")
        button.configuration?.baseForegroundColor = .white
        button.configuration?.cornerStyle = .large
        button.configuration?.buttonSize = .large
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLayout()
        setupActions()
        
        // Initialize with mock locations (replace with actual locations)
        currentLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        destinationLocation = CLLocation(latitude: 34.0522, longitude: -118.2437)
        calculateRouteInfo()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .clear
    }
    
    private func setupActions() {
        transportSegmentedControl.addTarget(self, action: #selector(transportModeChanged), for: .valueChanged)
        startJourneyButton.addTarget(self, action: #selector(startJourneyButtonTapped), for: .touchUpInside)
    }
    
    private func setupLayout() {
        view.addSubview(containerView)
        containerView.addSubview(transportSegmentedControl)
        containerView.addSubview(routeInfoStack)
        
        routeInfoStack.addArrangedSubview(distanceContainer)
        distanceContainer.addSubview(distanceLabel)
        distanceContainer.addSubview(distanceSubtitleLabel)
        
        routeInfoStack.addArrangedSubview(timeInfoLabel)
        containerView.addSubview(startJourneyButton)
        
        [containerView, transportSegmentedControl, routeInfoStack, distanceContainer,
         distanceLabel, distanceSubtitleLabel, timeInfoLabel, startJourneyButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            transportSegmentedControl.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            transportSegmentedControl.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            transportSegmentedControl.widthAnchor.constraint(equalToConstant: 200),
            transportSegmentedControl.heightAnchor.constraint(equalToConstant: 32),
            
            routeInfoStack.topAnchor.constraint(equalTo: transportSegmentedControl.bottomAnchor, constant: 24),
            routeInfoStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            routeInfoStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            distanceContainer.heightAnchor.constraint(equalToConstant: 100),
            distanceContainer.widthAnchor.constraint(equalToConstant: 200),
            
            distanceLabel.centerXAnchor.constraint(equalTo: distanceContainer.centerXAnchor),
            distanceLabel.centerYAnchor.constraint(equalTo: distanceContainer.centerYAnchor, constant: -10),
            
            distanceSubtitleLabel.centerXAnchor.constraint(equalTo: distanceContainer.centerXAnchor),
            distanceSubtitleLabel.topAnchor.constraint(equalTo: distanceLabel.bottomAnchor, constant: 4),
            
            startJourneyButton.topAnchor.constraint(equalTo: routeInfoStack.bottomAnchor, constant: 24),
            startJourneyButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            startJourneyButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            startJourneyButton.heightAnchor.constraint(equalToConstant: 50),
            startJourneyButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -34)
        ])
    }
    
    private func createSegmentItem(systemName: String, title: String) -> String {
        return title
    }
    
    // MARK: - Helper Methods
    private func calculateRouteInfo() {
        guard let currentLocation = currentLocation,
              let destinationLocation = destinationLocation else {
            return
        }
        
        let distance = currentLocation.distance(from: destinationLocation) / 1000 // Convert to kilometers
        let speedKmH = selectedTransportMode == .car ? 60.0 : 80.0 // Average speed
        let timeHours = distance / speedKmH
        
        let hours = Int(timeHours)
        let minutes = Int((timeHours - Double(hours)) * 60)
        
        // Update distance label
        distanceLabel.text = "\(Int(distance)) km"
        
        // Update time label
        let transportEmoji = selectedTransportMode == .car ? "🚗" : "🚂"
        timeInfoLabel.text = "\(transportEmoji) Estimated time: \(hours)h \(minutes)m"
    }
    
    // MARK: - Actions
    @objc private func transportModeChanged(_ sender: UISegmentedControl) {
        selectedTransportMode = TransportMode(rawValue: sender.selectedSegmentIndex) ?? .car
    }
    
    @objc private func startJourneyButtonTapped() {
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Add your journey start logic here
        print("Start Journey Button Tapped")
    }
}
