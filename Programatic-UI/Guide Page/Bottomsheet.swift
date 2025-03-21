import UIKit
import MapKit
import CoreLocation

class BottomSheetViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    private let sourceCoordinate: CLLocationCoordinate2D
    private let destinationAddress: String
    private let locationManager = CLLocationManager()
    private var bottomSheetView: UIView!
    private var bottomSheetTopConstraint: NSLayoutConstraint!
    private let bottomSheetCollapsedHeight: CGFloat = 0
    private let bottomSheetExpandedHeight: CGFloat = UIScreen.main.bounds.height * 0.8
    private var routeInfoView: UIView?
    
    init(sourceCoordinate: CLLocationCoordinate2D, destinationAddress: String) {
        self.sourceCoordinate = sourceCoordinate
        self.destinationAddress = destinationAddress
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBottomSheet()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    private func setupBottomSheet() {
        bottomSheetView = UIView()
        bottomSheetView.backgroundColor = UIColor(hex: "#333333")
        bottomSheetView.layer.cornerRadius = 18
        bottomSheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        bottomSheetView.clipsToBounds = true
        view.addSubview(bottomSheetView)  // Fixed typo
        
        bottomSheetView.translatesAutoresizingMaskIntoConstraints = false
        bottomSheetTopConstraint = bottomSheetView.topAnchor.constraint(equalTo: view.bottomAnchor, constant: -bottomSheetCollapsedHeight)
        NSLayoutConstraint.activate([
            bottomSheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomSheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomSheetView.heightAnchor.constraint(equalToConstant: bottomSheetExpandedHeight),
            bottomSheetTopConstraint
        ])
        
        let dragHandle = UIView()
        dragHandle.backgroundColor = .systemGray
        dragHandle.layer.cornerRadius = 3
        dragHandle.translatesAutoresizingMaskIntoConstraints = false
        bottomSheetView.addSubview(dragHandle)
        
        NSLayoutConstraint.activate([
            dragHandle.topAnchor.constraint(equalTo: bottomSheetView.topAnchor, constant: 8),
            dragHandle.centerXAnchor.constraint(equalTo: bottomSheetView.centerXAnchor),
            dragHandle.widthAnchor.constraint(equalToConstant: 40),
            dragHandle.heightAnchor.constraint(equalToConstant: 6)
        ])
        
        let mapView = MKMapView()
            mapView.translatesAutoresizingMaskIntoConstraints = false
            mapView.showsUserLocation = true
            mapView.delegate = self
            mapView.showsCompass = false
            bottomSheetView.addSubview(mapView)

            NSLayoutConstraint.activate([
                mapView.topAnchor.constraint(equalTo: dragHandle.bottomAnchor, constant: 10),
                mapView.leadingAnchor.constraint(equalTo: bottomSheetView.leadingAnchor, constant: 10),
                mapView.trailingAnchor.constraint(equalTo: bottomSheetView.trailingAnchor, constant: -10),
                mapView.bottomAnchor.constraint(equalTo: bottomSheetView.bottomAnchor, constant: -10)
            ])

            let compassButton = MKCompassButton(mapView: mapView)
            compassButton.compassVisibility = .visible
            compassButton.translatesAutoresizingMaskIntoConstraints = false
            bottomSheetView.addSubview(compassButton)

            NSLayoutConstraint.activate([
                compassButton.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 50),
                compassButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -16)
            ])
        
        let closeButton = UIButton(type: .custom)
        closeButton.setTitle("✕", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = UIColor(hex: "#555555")
        closeButton.layer.cornerRadius = 12
        closeButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        closeButton.addTarget(self, action: #selector(closeBottomSheet), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        bottomSheetView.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        bottomSheetView.addGestureRecognizer(panGesture)
        
        UIView.animate(withDuration: 0.3) {
            self.bottomSheetTopConstraint.constant = -self.bottomSheetExpandedHeight
            self.view.layoutIfNeeded()
        }
        
        drawRoute(on: mapView, from: sourceCoordinate, to: destinationAddress)
    }
    
    private func displayRouteInfoView(for route: MKRoute, mapView: MKMapView) {
        routeInfoView = UIView()
        routeInfoView?.backgroundColor = UIColor(hex: "#222222")
        routeInfoView?.layer.cornerRadius = 12
        routeInfoView?.layer.shadowColor = UIColor.black.cgColor
        routeInfoView?.layer.shadowOpacity = 0.5
        routeInfoView?.layer.shadowOffset = CGSize(width: 0, height: 4)
        routeInfoView?.layer.shadowRadius = 8
        
        routeInfoView?.translatesAutoresizingMaskIntoConstraints = false
        mapView.addSubview(routeInfoView!)
        
        NSLayoutConstraint.activate([
            routeInfoView!.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 16),
            routeInfoView!.leadingAnchor.constraint(equalTo: mapView.leadingAnchor, constant: 16),
            routeInfoView!.widthAnchor.constraint(equalToConstant: 220),
            routeInfoView!.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        let carIcon = UIImageView(image: UIImage(systemName: "car.fill"))
        carIcon.tintColor = .white
        carIcon.translatesAutoresizingMaskIntoConstraints = false
        routeInfoView?.addSubview(carIcon)
        
        NSLayoutConstraint.activate([
            carIcon.leadingAnchor.constraint(equalTo: routeInfoView!.leadingAnchor, constant: 12),
            carIcon.centerYAnchor.constraint(equalTo: routeInfoView!.centerYAnchor),
            carIcon.widthAnchor.constraint(equalToConstant: 20),
            carIcon.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        let distanceAndTimeLabel = UILabel()
        let timeInHours = route.expectedTravelTime / 3600
        let timeInMinutes = (route.expectedTravelTime.truncatingRemainder(dividingBy: 3600)) / 60
        distanceAndTimeLabel.text = String(format: "%.2f km • %.0fh %.0fm",
                                          route.distance / 1000,
                                          timeInHours,
                                          timeInMinutes)
        distanceAndTimeLabel.textColor = .white
        distanceAndTimeLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        distanceAndTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        routeInfoView?.addSubview(distanceAndTimeLabel)
        
        NSLayoutConstraint.activate([
            distanceAndTimeLabel.leadingAnchor.constraint(equalTo: carIcon.trailingAnchor, constant: 6),
            distanceAndTimeLabel.centerYAnchor.constraint(equalTo: routeInfoView!.centerYAnchor),
            distanceAndTimeLabel.trailingAnchor.constraint(lessThanOrEqualTo: routeInfoView!.trailingAnchor, constant: -12)
        ])
    }
    
    @objc private func closeBottomSheet() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: view)
        let velocity = recognizer.velocity(in: view)
        
        switch recognizer.state {
        case .changed:
            let newConstant = bottomSheetTopConstraint.constant + translation.y
            if newConstant <= -bottomSheetCollapsedHeight && newConstant >= -bottomSheetExpandedHeight {
                bottomSheetTopConstraint.constant = newConstant
            }
            recognizer.setTranslation(.zero, in: view)
            
        case .ended:
            let targetPosition: CGFloat = velocity.y > 0 ? -bottomSheetCollapsedHeight : -bottomSheetExpandedHeight
            UIView.animate(withDuration: 0.3) {
                self.bottomSheetTopConstraint.constant = targetPosition
                self.view.layoutIfNeeded()
            }
            if targetPosition == -bottomSheetCollapsedHeight {
                dismiss(animated: true, completion: nil)
            }
        
        default:
            break
        }
    }
    
    private func drawRoute(on mapView: MKMapView, from sourceCoordinate: CLLocationCoordinate2D, to destinationAddress: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(destinationAddress) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            // Check for geocoding error or no placemarks
            if let error = error as? CLError, error.code == .geocodeFoundNoResult {
                self.showAlert(message: "Location not found for the provided address")
                return
            } else if let error = error {
                self.showAlert(message: "Geocoding error: \(error.localizedDescription)")
                return
            }
            
            guard let placemark = placemarks?.first, let destinationCoordinate = placemark.location?.coordinate else {
                self.showAlert(message: "Location not found for the provided address")
                return
            }
            
            let sourcePlacemark = MKPlacemark(coordinate: sourceCoordinate)
            let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
            
            let directionRequest = MKDirections.Request()
            directionRequest.source = MKMapItem(placemark: sourcePlacemark)
            directionRequest.destination = MKMapItem(placemark: destinationPlacemark)
            directionRequest.transportType = .automobile
            
            let directions = MKDirections(request: directionRequest)
            directions.calculate { response, error in
                if let error = error {
                    self.showAlert(message: "Error calculating directions: \(error.localizedDescription)")
                    return
                }
                guard let response = response, let route = response.routes.first else {
                    self.showAlert(message: "No routes found")
                    return
                }
                
                mapView.addOverlay(route.polyline, level: .aboveRoads)
                let region = MKCoordinateRegion(route.polyline.boundingMapRect)
                mapView.setRegion(region, animated: true)
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = destinationCoordinate
                annotation.title = self.destinationAddress
                mapView.addAnnotation(annotation)
                
                self.displayRouteInfoView(for: route, mapView: mapView)
            }
        }
    }
    
    private func showAlert(message: String) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: "Navigation Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                self?.dismiss(animated: true)
            })
            alert.view.tintColor = UIColor(hex: "#40CBD8")
            self?.present(alert, animated: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 4.0
            return renderer
        }
        return MKOverlayRenderer()
    }
}
