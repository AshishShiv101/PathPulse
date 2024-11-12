import UIKit
import MapKit
import CoreLocation

class MapPage: UIViewController, CLLocationManagerDelegate, UISearchBarDelegate, MKMapViewDelegate {
    let locationManager = CLLocationManager()
    let mapView = MKMapView()
    private let bottomSheetView = UIView()
    let searchBar = UISearchBar()
    private var bottomSheetTopConstraint: NSLayoutConstraint!
    var startLocationCoordinate: CLLocationCoordinate2D?
    var destinationCoordinate: CLLocationCoordinate2D?
    private let bottomSheetCollapsedHeight: CGFloat = 135
    private let bottomSheetMediumHeight: CGFloat = 300
    private let bottomSheetExpandedHeight: CGFloat = 800
    let searchButton = UIButton()
    let directionButton = UIButton()
    let sosButton = UIButton()

    
    
    
    private var sosTappedButton: Bool = false {
        didSet {
            sosOverlayView.isHidden = !sosTappedButton
        }
    }

    
    
    
    
    private let sosOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#1e1e1e")
        view.layer.cornerRadius = 10
        view.isHidden = true
        return view
    }()
    
    private func setupSOSOverlayView() {
        sosOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        sosOverlayView.layer.cornerRadius = 16
        sosOverlayView.clipsToBounds = true
        
        // Top Icon (Add Contact)
        let topIconImageView = UIImageView()
        topIconImageView.image = UIImage(systemName: "person.crop.circle.badge.plus") // Adjust icon as needed
        topIconImageView.tintColor = .white
        topIconImageView.contentMode = .scaleAspectFit
        
        // Title Label
        let titleLabel = UILabel()
        titleLabel.text = "Add Contacts"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        
        // Emergency Contact Icons and Labels
        let ambulanceIcon = createContactIcon(with: "cross.circle.fill", label: "Ambulance")
        let womenHelplineIcon = createContactIcon(with: "figure.stand.dress", label: "Women")
        let fireHelplineIcon = createContactIcon(with: "flame.fill", label: "Fire")
        
        // Stack for Emergency Contacts
        let contactsStackView = UIStackView(arrangedSubviews: [ambulanceIcon, womenHelplineIcon, fireHelplineIcon])
        contactsStackView.axis = .horizontal
        contactsStackView.alignment = .center
        contactsStackView.distribution = .equalSpacing
        contactsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Main Stack for Top Icon, Title, and Contacts Stack
        let mainStackView = UIStackView(arrangedSubviews: [topIconImageView, titleLabel, contactsStackView])
        mainStackView.axis = .vertical
        mainStackView.spacing = 16
        mainStackView.alignment = .center
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        
        sosOverlayView.addSubview(mainStackView)
        
        // Constraints
        NSLayoutConstraint.activate([
            mainStackView.centerXAnchor.constraint(equalTo: sosOverlayView.centerXAnchor),
            mainStackView.centerYAnchor.constraint(equalTo: sosOverlayView.centerYAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: sosOverlayView.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: sosOverlayView.trailingAnchor, constant: -20),
            
            topIconImageView.heightAnchor.constraint(equalToConstant: 50),
            topIconImageView.widthAnchor.constraint(equalToConstant: 50),
            
            contactsStackView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    // Helper function to create icon with label
    private func createContactIcon(with systemImageName: String, label: String) -> UIView {
        // Icon image view
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: systemImageName)
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Label for icon description
        let iconLabel = UILabel()
        iconLabel.text = label
        iconLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        iconLabel.textColor = .white
        iconLabel.textAlignment = .center
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Stack view to hold the icon and label
        let stackView = UIStackView(arrangedSubviews: [iconImageView, iconLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Constraints for icon size
        NSLayoutConstraint.activate([
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            iconImageView.widthAnchor.constraint(equalToConstant: 40)
        ])
        
        // Container view to add a leading margin
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 22),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -22), // Equal padding on both sides
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0), // Optional: Adjust top padding if needed
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0) // Optional: Adjust bottom padding if needed
        ])

        
        return containerView
    }


    

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupBottomSheet()
        setupSOSButton()
        setupSOSOverlayView() // Set up overlay view
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        searchBar.delegate = self
        mapView.showsUserLocation = true
        mapView.delegate = self
        setDefaultLocation()

        // Adding sosOverlayView to the view
        view.addSubview(sosOverlayView)
        sosOverlayView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            sosOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            sosOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            sosOverlayView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 150),
            sosOverlayView.heightAnchor.constraint(equalToConstant: 220) // Adjust height as needed
        ])
        
        

        
        
        
        view.bringSubviewToFront(bottomSheetView)
       
        
        
        
        
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
    }

    private func setupBottomSheet() {
        bottomSheetView.backgroundColor = UIColor(hex: "#151515").withAlphaComponent(0.85)
        bottomSheetView.layer.cornerRadius = 18
        bottomSheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        bottomSheetView.clipsToBounds = true

        view.addSubview(bottomSheetView)
        bottomSheetView.translatesAutoresizingMaskIntoConstraints = false
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

    private func setupSOSButton() {
        sosButton.setTitle("SOS", for: .normal)
        sosButton.backgroundColor = .red
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


    
    
    
    @objc private func sosButtonTapped() {
        sosTappedButton.toggle()
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
            textField.backgroundColor = UIColor.white
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
    }
    

    
    @objc private func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: view)
        let velocity = recognizer.velocity(in: view)
        
        // Calculate new position, limiting it to the default collapsed position
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

    
    
    private func setDefaultLocation() {
        let kolkatalocation = CLLocationCoordinate2D(latitude: 22.57, longitude: 88.36)
        let region = MKCoordinateRegion(center: kolkatalocation, latitudinalMeters: 10000, longitudinalMeters: 10000)
        mapView.setRegion(region, animated: true)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let userLocation = locations.last {
            let region = MKCoordinateRegion(center: userLocation.coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
            mapView.setRegion(region, animated: true)
        }
        locationManager.stopUpdatingLocation()
    }

    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        guard let searchText = searchBar.text else { return }
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchText
        
        let activeSearch = MKLocalSearch(request: searchRequest)
        activeSearch.start { response, error in
            guard let response = response, error == nil else { return }
            
            // Get the coordinates of the first search result
            let coordinate = response.mapItems.first?.placemark.coordinate ?? CLLocationCoordinate2D()
            
   
            self.addSearchResultAnnotation(for: coordinate)
            
        
            if self.startLocationCoordinate == nil {
                self.startLocationCoordinate = coordinate
            } else {
                self.destinationCoordinate = coordinate
                self.getDirections(from: self.startLocationCoordinate!, to: coordinate)
            }
        }
    }
    
    
    
    
    func addSearchResultAnnotation(for coordinate: CLLocationCoordinate2D) {
        mapView.removeAnnotations(mapView.annotations)

        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: true)
    }
    
    
    
    
    
    private func getDirections(from startCoordinate: CLLocationCoordinate2D, to destinationCoordinate: CLLocationCoordinate2D) {
        let startPlacemark = MKPlacemark(coordinate: startCoordinate)
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
        
        let startMapItem = MKMapItem(placemark: startPlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        
        let request = MKDirections.Request()
        request.source = startMapItem
        request.destination = destinationMapItem
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            guard let response = response, error == nil else { return }
            
            self.mapView.removeOverlays(self.mapView.overlays)
            
            // Add the route to the map
            if let route = response.routes.first {
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    
    
    
    
    
    @objc private func directionButtonTapped() {
        guard let startCoordinate = startLocationCoordinate, let destinationCoordinate = destinationCoordinate else { return }
        getDirections(from: startCoordinate, to: destinationCoordinate)
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

    
    
    
    
    
    
    @objc private func searchButtonTapped() {
        searchBar.becomeFirstResponder()
    }
}
