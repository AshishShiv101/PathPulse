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
    private let bottomSheetCollapsedHeight: CGFloat = 120
    private let bottomSheetMediumHeight: CGFloat = 300
    private let bottomSheetExpandedHeight: CGFloat = 800
    let searchButton = UIButton()
    let directionButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupBottomSheet()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        searchBar.delegate = self
        mapView.showsUserLocation = true
        mapView.delegate = self
        setDefaultLocation()
    }
    
    // MARK: - UI Setup
    private func setupViews() {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        
        NSLayoutConstraint.activate([
            // Map view constraints without respecting safe area
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

    private func addContentToBottomSheet() {
        let rectangleView = UIView()
                rectangleView.backgroundColor = .systemGray
                rectangleView.layer.cornerRadius = 10
                rectangleView.translatesAutoresizingMaskIntoConstraints = false
                bottomSheetView.addSubview(rectangleView)
                NSLayoutConstraint.activate([
                    rectangleView.topAnchor.constraint(equalTo: bottomSheetView.topAnchor, constant: 10),
                    rectangleView.centerXAnchor.constraint(equalTo: bottomSheetView.centerXAnchor),
                    rectangleView.widthAnchor.constraint(equalToConstant: 60),  // Set width as desired
                    rectangleView.heightAnchor.constraint(equalToConstant: 5)   // Set height as desired
                ])
        
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        bottomSheetView.addSubview(searchBar)

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
            
            // Set target position based on the nearest height threshold
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
        let chennaiLocation = CLLocationCoordinate2D(latitude: 13.0827, longitude: 80.2707)
        let region = MKCoordinateRegion(center: chennaiLocation, latitudinalMeters: 10000, longitudinalMeters: 10000)
        mapView.setRegion(region, animated: true)
    }

    // MARK: - Location Manager Delegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let userLocation = locations.last {
            let region = MKCoordinateRegion(center: userLocation.coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
            mapView.setRegion(region, animated: true)
        }
        locationManager.stopUpdatingLocation()
    }

    // MARK: - Search Bar Delegate
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
            
            // Update the map with the new location
            self.addSearchResultAnnotation(for: coordinate)
            
            // If it's the first search, set as start location, else set as destination
            if self.startLocationCoordinate == nil {
                self.startLocationCoordinate = coordinate
            } else {
                self.destinationCoordinate = coordinate
                self.getDirections(from: self.startLocationCoordinate!, to: coordinate)
            }
        }
    }

    // MARK: - Add Annotation for Search Result
    func addSearchResultAnnotation(for coordinate: CLLocationCoordinate2D) {
        // Remove existing annotations
        mapView.removeAnnotations(mapView.annotations)
        
        // Add new annotation
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        // Center the map on the selected place
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: true)
    }

    // MARK: - Get Directions Between Two Locations
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

    // MARK: - Direction Button Action
    @objc private func directionButtonTapped() {
        guard let startCoordinate = startLocationCoordinate, let destinationCoordinate = destinationCoordinate else { return }
        getDirections(from: startCoordinate, to: destinationCoordinate)
    }

    // MARK: - Map View Delegate for Rendering the Route
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .blue
            renderer.lineWidth = 4
            return renderer
        }
        return MKOverlayRenderer()
    }

    // MARK: - Search Button Action
    @objc private func searchButtonTapped() {
        searchBar.becomeFirstResponder()
    }
}
