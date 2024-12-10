import MapKit
import CoreLocation
class CitySearchHelper {
    static let shared = CitySearchHelper()
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
                return
            }
            guard let response = response, let mapItem = response.mapItems.first else {
                print("No results found")
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
            let shortestRoute = routes.min(by: { $0.distance < $1.distance })
            
            for route in routes {
                mapView.addOverlay(route.polyline, level: .aboveRoads)
            }
            if let shortestRoute = shortestRoute {
                print("Shortest route distance: \(shortestRoute.distance / 1000) km")
                
                // Set the shortest route as a property for reference in the delegate
                mapView.addOverlay(shortestRoute.polyline, level: .aboveRoads)
                
                // Zoom in to the shortest route
                let rect = shortestRoute.polyline.boundingMapRect
                mapView.setRegion(MKCoordinateRegion(rect), animated: true)
            }
        }
    }


        
        var mapView: MKMapView!
        var shortestRoutePolyline: MKPolyline?
        
        // Other methods for setup, map view handling, etc.
        
        func calculateMultipleRoutes(from startCoordinate: CLLocationCoordinate2D, to destinationCoordinate: CLLocationCoordinate2D) {
            mapView.removeOverlays(mapView.overlays)
            
            let startPlacemark = MKPlacemark(coordinate: startCoordinate)
            let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
            
            let startItem = MKMapItem(placemark: startPlacemark)
            let destinationItem = MKMapItem(placemark: destinationPlacemark)
            
            let request = MKDirections.Request()
            request.source = startItem
            request.destination = destinationItem
            request.transportType = .automobile
            
            let directions = MKDirections(request: request)
            directions.calculate { [weak self] (response, error) in
                if let error = error {
                    print("Error calculating directions: \(error.localizedDescription)")
                    return
                }
                
                guard let routes = response?.routes else {
                    print("No routes found")
                    return
                }
                
                // Find the shortest route based on distance
                if let shortestRoute = routes.min(by: { $0.distance < $1.distance }) {
                    self?.shortestRoutePolyline = shortestRoute.polyline
                }
                
                // Add all routes to map
                for route in routes {
                    let polyline = route.polyline
                    self?.mapView.addOverlay(polyline)
                }
            }
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                
                // Highlight the shortest route with a different color
                if polyline == shortestRoutePolyline {
                    renderer.strokeColor = .red // Shortest route in red
                } else {
                    renderer.strokeColor = .blue // Other routes in blue
                }
                
                renderer.lineWidth = 4
                return renderer
            }
            
            return MKOverlayRenderer()
        }
    }


