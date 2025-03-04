import MapKit
import CoreLocation

class CitySearchHelper {
    static let shared = CitySearchHelper()
    private static var routeInfoViews: [UIView] = []
    static func searchForCity(
        city: String,
        mapView: MKMapView,
        locationManager: CLLocationManager,
        completion: @escaping (WeatherData?, Error?) -> Void
    ) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = city
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        
        search.start { (response, error) in
            if let error = error {
                print("Error while searching for city: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            guard let response = response, let mapItem = response.mapItems.first else {
                print("No results found")
                completion(nil, nil)
                return
            }
            
            let destinationCoordinate = mapItem.placemark.coordinate
            let region = MKCoordinateRegion(
                center: destinationCoordinate,
                latitudinalMeters: 10000,
                longitudinalMeters: 10000
            )
            mapView.setRegion(region, animated: true)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = destinationCoordinate
            annotation.title = mapItem.name
            mapView.addAnnotation(annotation)
            
            WeatherService.shared.fetchWeather(for: destinationCoordinate) { (weatherData, error) in
                if let error = error {
                    print("Error fetching weather: \(error.localizedDescription)")
                    completion(nil, error)
                    return
                }
                guard let weatherData = weatherData else {
                    print("No weather data available")
                    completion(nil, nil)
                    return
                }
                completion(weatherData, nil)
            }
            
            if let currentLocation = locationManager.location?.coordinate {
                let distance = calculateDistance(from: currentLocation, to: destinationCoordinate)
                print("Distance to destination: \(distance) km")
                
                annotation.subtitle = String(format: "Distance: %.2f km", distance)
                mapView.addAnnotation(annotation)
                
                calculateRoute(from: currentLocation, to: destinationCoordinate, mapView: mapView)
            }
        }
    }
    private static func calculateDistance(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
        let distanceInMeters = startLocation.distance(from: endLocation)
        return distanceInMeters / 1000.0
    }
    static func calculateRoute(from startCoordinate: CLLocationCoordinate2D, to destinationCoordinate: CLLocationCoordinate2D, mapView: MKMapView) {
        mapView.removeOverlays(mapView.overlays)
        
        let startPlacemark = MKPlacemark(coordinate: startCoordinate)
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
        
        let startItem = MKMapItem(placemark: startPlacemark)
        let destinationItem = MKMapItem(placemark: destinationPlacemark)
        
        let request = MKDirections.Request()
        request.source = startItem
        request.destination = destinationItem
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: request)
        directions.calculate { (response, error) in
            if let error = error {
                print("Error calculating directions: \(error.localizedDescription)")
                return
            }
            guard let routes = response?.routes else {
                print("No routes found")
                return
            }
            
            let sortedRoutes = routes.sorted { $0.distance < $1.distance }
            let shortestRoute = sortedRoutes.first
            let longestRoute = sortedRoutes.last
            
            routeInfoViews.forEach { $0.removeFromSuperview() }
            routeInfoViews.removeAll()
            
            for (index, route) in sortedRoutes.enumerated() {
                let isShortest = route === shortestRoute // Using identity comparison
                let isLongest = route === longestRoute   // Using identity comparison
                
                // Store the flags directly in the polyline's userInfo
                let routeInfo: [String: Any] = [
                    "index": index,
                    "isShortest": isShortest,
                    "isLongest": isLongest
                ]
                
                route.polyline.title = String(index) // Add a title as backup
                route.polyline.subtitle = "\(isShortest),\(isLongest)" // Add flags as subtitle for debugging
                
                mapView.addOverlay(route.polyline, level: .aboveRoads)
                displayRouteInfoView(for: route, at: index, mapView: mapView, isShortest: isShortest, isLongest: isLongest)
                
                // Debug print to verify
                print("Route \(index): isShortest=\(isShortest), isLongest=\(isLongest), distance=\(route.distance)")
            }
            
            if let shortestRoute = shortestRoute {
                mapView.setVisibleMapRect(shortestRoute.polyline.boundingMapRect, animated: true)
            }
        }
    }
    static func displayRouteInfoView(for route: MKRoute, at index: Int, mapView: MKMapView, isShortest: Bool, isLongest: Bool) {
        let routeInfoView = UIView()
        routeInfoView.backgroundColor = UIColor(hex: "#222222")
        routeInfoView.layer.cornerRadius = 12
        routeInfoView.layer.shadowColor = UIColor.black.cgColor
        routeInfoView.layer.shadowOpacity = 0.5
        routeInfoView.layer.shadowOffset = CGSize(width: 0, height: 4)
        routeInfoView.layer.shadowRadius = 8
        
        // Border styling based on route status
        routeInfoView.layer.borderWidth = 2
        if isShortest {
            routeInfoView.layer.borderColor = UIColor.systemGreen.cgColor
        } else if isLongest {
            routeInfoView.layer.borderColor = UIColor.systemRed.cgColor
        } else {
            routeInfoView.layer.borderColor = UIColor.clear.cgColor
        }
        
        let topMargin: Int = 70
        routeInfoView.frame = CGRect(x: 10, y: topMargin + (index * 70), width: 220, height: 60)
        
        // Add car icon
        let carIcon = UIImageView(image: UIImage(systemName: "car.fill"))
        carIcon.tintColor = .white
        carIcon.frame = CGRect(x: 12, y: 20, width: 20, height: 20)
        routeInfoView.addSubview(carIcon)
        
        // Distance and time label (adjusted to accommodate car icon)
        let distanceAndTimeLabel = UILabel()
        let timeInHours = route.expectedTravelTime / 3600
        let timeInMinutes = (route.expectedTravelTime.truncatingRemainder(dividingBy: 3600)) / 60
        
        distanceAndTimeLabel.text = String(format: "%.2f km • %.0fh %.0fm",
                                           route.distance / 1000,
                                           timeInHours,
                                           timeInMinutes)
        distanceAndTimeLabel.textColor = .white
        distanceAndTimeLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        distanceAndTimeLabel.frame = CGRect(x: 38, y: 15, width: 200, height: 30)
        routeInfoView.addSubview(distanceAndTimeLabel)
        
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = UIColor(hex: "#40cbd8")
        closeButton.frame = CGRect(x: routeInfoView.frame.width - 32, y: 12, width: 24, height: 24)
        closeButton.addAction(UIAction { _ in
            if let index = mapView.overlays.firstIndex(where: { ($0 as? MKPolyline)?.userInfo as? Int == index }) {
                mapView.removeOverlay(mapView.overlays[index])
            }
            routeInfoView.removeFromSuperview()
        }, for: .touchUpInside)
        routeInfoView.addSubview(closeButton)
        
        mapView.superview?.addSubview(routeInfoView)
        route.polyline.userInfo = index
        routeInfoViews.append(routeInfoView)
    }
}
func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    if let polyline = overlay as? MKPolyline {
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.lineWidth = 4
        
        if let subtitle = polyline.subtitle {
            let flags = subtitle.split(separator: ",")
            let isShortest = flags[0] == "true"
            let isLongest = flags[1] == "true"
            
            if isShortest {
                renderer.strokeColor = .systemGreen
            } else if isLongest {
                renderer.strokeColor = .systemRed
            } else {
                renderer.strokeColor = .blue
            }
            
            // Debug print
            print("Rendering polyline - shortest: \(isShortest), longest: \(isLongest)")
        } else {
            renderer.strokeColor = .blue // Default
            print("No subtitle found for polyline")
        }
        
        return renderer
    }
    return MKOverlayRenderer()
}

extension MKPolyline {
    private struct AssociatedKeys {
        static var userInfo = "userInfo"
    }
    var userInfo: Any? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.userInfo)
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.userInfo, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
