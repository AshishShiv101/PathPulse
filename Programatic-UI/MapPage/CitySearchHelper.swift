import MapKit
import CoreLocation
class CitySearchHelper {
    static func searchForCity(city: String, mapView: MKMapView, locationManager: CLLocationManager, completion: @escaping (WeatherData?, Error?) -> Void) {
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
            
            WeatherService.shared.fetchWeather(for: destinationCoordinate) { (weatherData, error) in
                if let error = error {
                    print("Error fetching weather: \(error.localizedDescription)")
                    return
                }
                
                guard let weatherData = weatherData else {
                    print("No weather data available")
                    return
                }
                
                completion(weatherData, nil)
            }
            
            if let currentLocation = locationManager.location?.coordinate {
                calculateRoute(from: currentLocation, to: destinationCoordinate, mapView: mapView)
            }
        }
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
        
        let directions = MKDirections(request: request)
        directions.calculate { (response, error) in
            if let error = error {
                print("Error calculating directions: \(error.localizedDescription)")
                return
            }
            
            guard let route = response?.routes.first else {
                print("No routes found")
                return
            }
            
            mapView.addOverlay(route.polyline, level: .aboveRoads)
            
            let rect = route.polyline.boundingMapRect
            mapView.setRegion(MKCoordinateRegion(rect), animated: true)
        }
    }

}
