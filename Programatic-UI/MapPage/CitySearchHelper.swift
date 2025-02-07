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
        return distanceInMeters / 1000.0 // Convert meters to kilometers
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
                mapView.addOverlay(route.polyline, level: .aboveRoads)
                let isShortest = route == shortestRoute
                let isLongest = route == longestRoute
                displayRouteInfoView(for: route, at: index, mapView: mapView, isShortest: isShortest, isLongest: isLongest)
            }
            
            if let shortestRoute = shortestRoute {
                mapView.setVisibleMapRect(shortestRoute.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    static func displayRouteInfoView(for route: MKRoute, at index: Int, mapView: MKMapView, isShortest: Bool, isLongest: Bool) {
        let routeInfoView = UIView()

        routeInfoView.backgroundColor = UIColor(hex: "#ffffff").withAlphaComponent(0.9)

        routeInfoView.layer.borderWidth = 2
        if isShortest {
            routeInfoView.layer.borderColor = UIColor.systemGreen.cgColor
        } else if isLongest {
            routeInfoView.layer.borderColor = UIColor.systemRed.cgColor
        } else {
            routeInfoView.layer.borderColor = UIColor.clear.cgColor
        }

        routeInfoView.layer.cornerRadius = 8
        routeInfoView.layer.shadowColor = UIColor.white.cgColor
        routeInfoView.layer.shadowOpacity = 0.3
        routeInfoView.layer.shadowOffset = CGSize(width: 0, height: 4)
        routeInfoView.layer.shadowRadius = 6

        let topMargin: Int = 70
        routeInfoView.frame = CGRect(x: 10, y: topMargin + (index * 90), width: 200, height: 80)

        let distanceAndTimeLabel = UILabel()
        let timeInHours = route.expectedTravelTime / 3600
        let timeInMinutes = (route.expectedTravelTime.truncatingRemainder(dividingBy: 3600)) / 60

        distanceAndTimeLabel.text = String(format: "%.2f km   %.0f hr %.0f min", route.distance / 1000, timeInHours, timeInMinutes)
        distanceAndTimeLabel.textColor = .black
        distanceAndTimeLabel.font = UIFont.systemFont(ofSize: 14)
        distanceAndTimeLabel.frame = CGRect(x: 10, y: 10, width: routeInfoView.frame.width - 20, height: 40)
        distanceAndTimeLabel.numberOfLines = 2
        distanceAndTimeLabel.textAlignment = .left
        routeInfoView.addSubview(distanceAndTimeLabel)

        let walkingTimeLabel = UILabel()
                let walkingSpeed: Double = 5.0 // Average walking speed in km/h

                let routeDistance = route.distance
                let walkingTimeInterval = (routeDistance / 1000.0) / walkingSpeed

                let hours = Int(walkingTimeInterval)
                let minutes = Int((walkingTimeInterval - Double(hours)) * 60)

                walkingTimeLabel.text = "Walking Time: \(hours) hr \(minutes) min"
                walkingTimeLabel.font = UIFont.systemFont(ofSize: 14)
                walkingTimeLabel.frame = CGRect(x: 10, y: 50, width: routeInfoView.frame.width - 20, height: 20)
                routeInfoView.addSubview(walkingTimeLabel)

        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .black
        closeButton.frame = CGRect(x: routeInfoView.frame.width - 30, y: 10, width: 20, height: 20)
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
        renderer.strokeColor = .blue
        renderer.lineWidth = 4
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
