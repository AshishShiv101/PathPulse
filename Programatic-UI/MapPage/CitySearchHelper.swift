import MapKit
import CoreLocation
import NotificationCenter

class CitySearchHelper {
    static let shared = CitySearchHelper()
    
    var destinationCoordinate: CLLocationCoordinate2D?
    
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

            CitySearchHelper.shared.destinationCoordinate = destinationCoordinate

            
            
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
            
            NotificationCenter.default.post(
                name: NSNotification.Name("DestinationCoordinateUpdated"),
                object: nil,
                userInfo: ["coordinate": destinationCoordinate]
            )
            
            // Fetch weather data for the destination
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
            
            // Calculate distance from current location
            if let currentLocation = locationManager.location?.coordinate {
                let distance = calculateDistance(from: currentLocation, to: destinationCoordinate)
                print("Distance to destination: \(distance) km")
                
                annotation.subtitle = String(format: "Distance: %.2f km", distance)
                mapView.addAnnotation(annotation)
                
                // Calculate and display route
                calculateRoute(from: currentLocation, to: destinationCoordinate, mapView: mapView)
            }
        }
    }
    
    // Helper function to calculate distance between two coordinates
    private static func calculateDistance(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
        let distanceInMeters = startLocation.distance(from: endLocation)
        return distanceInMeters / 1000.0 // Convert meters to kilometers
    }
    
    // Method to calculate and display multiple routes
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
        request.requestsAlternateRoutes = true // Request alternate routes
        
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
            
            // Sort routes by distance (shortest first)
            let sortedRoutes = routes.sorted { $0.distance < $1.distance }
            
            // Clear previous route info views
            routeInfoViews.forEach { $0.removeFromSuperview() }
            routeInfoViews.removeAll()
            
            // Add overlays for all routes and show corresponding info views
            for (index, route) in sortedRoutes.enumerated() {
                mapView.addOverlay(route.polyline, level: .aboveRoads)
                displayRouteInfoView(for: route, at: index, mapView: mapView)
            }
            
            // Highlight the shortest route as default
            if let shortestRoute = sortedRoutes.first {
                mapView.setVisibleMapRect(shortestRoute.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    // Method to display the route information (distance and time) in a table-like view
    static func displayRouteInfoView(for route: MKRoute, at index: Int, mapView: MKMapView) {
        // Create the view for route info
        let routeInfoView = UIView()
        routeInfoView.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        routeInfoView.layer.cornerRadius = 8
        routeInfoView.layer.shadowColor = UIColor.black.cgColor
        routeInfoView.layer.shadowOpacity = 0.3
        routeInfoView.layer.shadowOffset = CGSize(width: 0, height: 4)
        routeInfoView.layer.shadowRadius = 6
        
        // Add additional top margin
        let topMargin: Int = 70 // Adjust this value as needed
        routeInfoView.frame = CGRect(x: 10, y: topMargin + (index * 100), width: 250, height: 80)
        
        // Add distance label
        let distanceLabel = UILabel()
        distanceLabel.text = String(format: "Distance: %.2f km", route.distance / 1000)
        distanceLabel.font = UIFont.systemFont(ofSize: 14)
        distanceLabel.frame = CGRect(x: 10, y: 10, width: routeInfoView.frame.width - 20, height: 20)
        routeInfoView.addSubview(distanceLabel)
        
        // Add time label in hours and minutes
        let timeInHours = route.expectedTravelTime / 3600
        let timeInMinutes = (route.expectedTravelTime.truncatingRemainder(dividingBy: 3600)) / 60
        let timeLabel = UILabel()
        timeLabel.text = String(format: "Time: %.0f hr %.0f min", timeInHours, timeInMinutes)
        timeLabel.font = UIFont.systemFont(ofSize: 14)
        timeLabel.frame = CGRect(x: 10, y: 40, width: routeInfoView.frame.width - 20, height: 20)
        routeInfoView.addSubview(timeLabel)
        
        // Add the route info view to the map's superview
        mapView.superview?.addSubview(routeInfoView)
        
        // Store the view in the static container for later removal
        routeInfoViews.append(routeInfoView)
    }
}
