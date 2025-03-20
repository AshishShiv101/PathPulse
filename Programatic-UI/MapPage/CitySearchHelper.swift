import MapKit
import CoreLocation

class CitySearchHelper {
    static let shared = CitySearchHelper()
    private var routeInfoViews: [UIView] = []

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
                
                CitySearchHelper.shared.calculateRoute(from: currentLocation, to: destinationCoordinate, mapView: mapView)
            }
        }
    }

    private static func calculateDistance(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
        let distanceInMeters = startLocation.distance(from: endLocation)
        return distanceInMeters / 1000.0
    }

    private func calculateRoute(from startCoordinate: CLLocationCoordinate2D, to destinationCoordinate: CLLocationCoordinate2D, mapView: MKMapView) {
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
            
            self.routeInfoViews.forEach { $0.removeFromSuperview() }
            self.routeInfoViews.removeAll()
            
            for (index, route) in sortedRoutes.enumerated() {
                let isShortest = route === shortestRoute
                let isLongest = route === longestRoute
                
                let routeInfo: [String: Any] = [
                    "index": index,
                    "isShortest": isShortest,
                    "isLongest": isLongest
                ]
                
                route.polyline.title = String(index)
                route.polyline.subtitle = "\(isShortest),\(isLongest)"
                route.polyline.userInfo = routeInfo
                
                mapView.addOverlay(route.polyline, level: .aboveRoads)
                self.displayRouteInfoView(for: route, at: index, mapView: mapView, isShortest: isShortest, isLongest: isLongest)
                print("Route \(index): isShortest=\(isShortest), isLongest=\(isLongest), distance=\(route.distance), userInfo=\(routeInfo)")
            }
            
            if let shortestRoute = shortestRoute {
                mapView.setVisibleMapRect(shortestRoute.polyline.boundingMapRect, animated: true)
            }
        }
    }

    private func displayRouteInfoView(for route: MKRoute, at index: Int, mapView: MKMapView, isShortest: Bool, isLongest: Bool) {
        let routeInfoView = UIView()
        routeInfoView.backgroundColor = UIColor(hex: "#222222")
        routeInfoView.layer.cornerRadius = 12
        routeInfoView.layer.shadowColor = UIColor.black.cgColor
        routeInfoView.layer.shadowOpacity = 0.5
        routeInfoView.layer.shadowOffset = CGSize(width: 0, height: 4)
        routeInfoView.layer.shadowRadius = 8
        
        routeInfoView.layer.borderWidth = 2
        routeInfoView.layer.borderColor = isShortest ? UIColor.blue.cgColor : UIColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 1.0).cgColor
        
        let topMargin: Int = 70
        routeInfoView.frame = CGRect(x: 10, y: topMargin + (index * 70), width: 220, height: 60)
        
        let carIcon = UIImageView(image: UIImage(systemName: "car.fill"))
        carIcon.tintColor = .white
        carIcon.frame = CGRect(x: 12, y: 20, width: 20, height: 20)
        routeInfoView.addSubview(carIcon)
        
        let distanceAndTimeLabel = UILabel()
        let timeInHours = route.expectedTravelTime / 3600
        let timeInMinutes = (route.expectedTravelTime.truncatingRemainder(dividingBy: 3600)) / 60
        distanceAndTimeLabel.text = String(format: "%.2f km • %.0fh %.0fm", route.distance / 1000, timeInHours, timeInMinutes)
        distanceAndTimeLabel.textColor = .white
        distanceAndTimeLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        distanceAndTimeLabel.frame = CGRect(x: 38, y: 15, width: 200, height: 30)
        routeInfoView.addSubview(distanceAndTimeLabel)
        
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = UIColor(hex: "#40cbd8")
        closeButton.frame = CGRect(x: routeInfoView.frame.width - 32, y: 12, width: 24, height: 24)
        closeButton.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            
            print("Close button tapped for route index: \(index), isShortest: \(isShortest)")
            
          
            if let overlayToRemove = mapView.overlays.first(where: { overlay in
                guard let polyline = overlay as? MKPolyline,
                      let userInfo = polyline.userInfo as? [String: Any],
                      let overlayIndex = userInfo["index"] as? Int else { return false }
                return overlayIndex == index
            }) {
                mapView.removeOverlay(overlayToRemove)
                print("Removed overlay for route index: \(index)")
            } else {
                print("Failed to find overlay for route index: \(index)")
            }
            routeInfoView.removeFromSuperview()
            if let viewIndex = self.routeInfoViews.firstIndex(of: routeInfoView) {
                self.routeInfoViews.remove(at: viewIndex)
            }
            
            // Reposition remaining views
            UIView.animate(withDuration: 0.3) {
                for (newIndex, view) in self.routeInfoViews.enumerated() {
                    let newY = topMargin + (newIndex * 70)
                    view.frame = CGRect(x: 10, y: CGFloat(newY), width: view.frame.width, height: view.frame.height)
                }
            }
        }, for: .touchUpInside)
        routeInfoView.addSubview(closeButton)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleRouteSelection(_:)))
        routeInfoView.addGestureRecognizer(tapGesture)
        routeInfoView.isUserInteractionEnabled = true
        routeInfoView.tag = index
        
        mapView.superview?.addSubview(routeInfoView)
        self.routeInfoViews.append(routeInfoView)
    }

    @objc private func handleRouteSelection(_ sender: UITapGestureRecognizer) {
        guard let selectedView = sender.view, let mapView = selectedView.superview?.subviews.compactMap({ $0 as? MKMapView }).first else { return }
        
        let selectedIndex = selectedView.tag
        
        // Remove other routes from the map
        let overlaysToRemove = mapView.overlays.filter { overlay in
            if let polyline = overlay as? MKPolyline, let userInfo = polyline.userInfo as? [String: Any], let index = userInfo["index"] as? Int {
                return index != selectedIndex
            }
            return true
        }
        mapView.removeOverlays(overlaysToRemove)
        
        // Remove other route info views and animate the selected view to the top
        var indicesToRemove: [Int] = []
        for (index, view) in routeInfoViews.enumerated() {
            if view.tag != selectedIndex {
                view.removeFromSuperview()
                indicesToRemove.append(index)
            } else {
                UIView.animate(withDuration: 0.3, animations: {
                    view.frame = CGRect(x: 10, y: 70, width: view.frame.width, height: view.frame.height)
                })
            }
        }
        
        for index in indicesToRemove.reversed() {
            routeInfoViews.remove(at: index)
        }
    }
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
