import MapKit
import CoreLocation

class CitySearchHelper: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
    static let shared = CitySearchHelper()
    private var routeInfoViews: [UIView] = []
    private var currentRoute: MKRoute?
    private var mapViewReference: MKMapView?
    private var locationManager: CLLocationManager?
    private var lastWeatherUpdateLocation: CLLocation?
    private var distanceTraveled: Double = 0.0
    private let updateDistanceThreshold: Double = 2.0
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.startUpdatingLocation()
    }
    
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
        return distanceInMeters / 1000.0 // Distance in km
    }
    
    private func setupMapDelegate(for mapView: MKMapView) {
        mapView.delegate = self
        mapViewReference = mapView
    }
    
    private func calculateRoute(from startCoordinate: CLLocationCoordinate2D, to destinationCoordinate: CLLocationCoordinate2D, mapView: MKMapView) {
        setupMapDelegate(for: mapView)
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations.filter { $0 is MapPage.WeatherAnnotation })
        
        // Reset tracking variables when calculating new route
        distanceTraveled = 0.0
        lastWeatherUpdateLocation = nil
        
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
        directions.calculate { [weak self] (response, error) in
            guard let self = self else { return }
            if let error = error {
                print("Error calculating directions: \(error.localizedDescription)")
                return
            }
            guard let routes = response?.routes else {
                print("No routes found")
                return
            }
            
            let sortedRoutes = routes.sorted { $0.distance < $1.distance }
            self.currentRoute = sortedRoutes.first
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
                self.addFixedWeatherAnnotations(for: route, in: mapView, routeIndex: index)
                print("Route \(index): isShortest=\(isShortest), isLongest=\(isLongest), distance=\(route.distance), userInfo=\(routeInfo)")
            }
            
            if let shortestRoute = shortestRoute {
                mapView.setVisibleMapRect(shortestRoute.polyline.boundingMapRect, animated: true)
                self.lastWeatherUpdateLocation = CLLocation(latitude: startCoordinate.latitude,
                                                          longitude: startCoordinate.longitude)
            }
        }
    }
    
    private func addFixedWeatherAnnotations(for route: MKRoute, in mapView: MKMapView, routeIndex: Int) {
        let polyline = route.polyline
        let pointCount = polyline.pointCount
        let numberOfAnnotations = 5
        let intervalPoints = pointCount / (numberOfAnnotations - 1)
        
        var previousWeatherData: WeatherData? = nil
        
        for i in 0..<numberOfAnnotations {
            let pointIndex = i * intervalPoints
            let coordinate = polyline.points()[min(pointIndex, pointCount - 1)].coordinate
            
            fetchWeatherAndAddAnnotation(coordinate: coordinate, mapView: mapView, routeIndex: routeIndex) { weatherData in
                if let prevWeather = previousWeatherData, let newWeather = weatherData {
                    if self.isSignificantWeatherChange(previous: prevWeather, current: newWeather) {
                        let annotation = MapPage.WeatherAnnotation(coordinate: coordinate, weatherData: newWeather, routeIndex: routeIndex)
                        DispatchQueue.main.async {
                            mapView.addAnnotation(annotation)
                        }
                    }
                }
                previousWeatherData = weatherData
            }
        }
    }
    
    private func fetchWeatherAndAddAnnotation(coordinate: CLLocationCoordinate2D, mapView: MKMapView, routeIndex: Int, completion: ((WeatherData?) -> Void)? = nil) {
        WeatherService.shared.fetchWeather(for: coordinate) { (weatherData, error) in
            if let error = error {
                print("Error fetching weather for coordinate \(coordinate): \(error.localizedDescription)")
                completion?(nil)
                return
            }
            guard let weatherData = weatherData else {
                print("No weather data received for coordinate \(coordinate)")
                completion?(nil)
                return
            }
            let annotation = MapPage.WeatherAnnotation(coordinate: coordinate, weatherData: weatherData, routeIndex: routeIndex)
            DispatchQueue.main.async {
                mapView.addAnnotation(annotation)
            }
            completion?(weatherData)
        }
    }
    
    private func isSignificantWeatherChange(previous: WeatherData, current: WeatherData) -> Bool {
        let temperatureChange = abs(previous.temperature - current.temperature)
        let humidityChange = abs(previous.humidity - current.humidity)
        let windSpeedChange = abs(previous.windSpeed - current.windSpeed)
        
        return temperatureChange > 5 || humidityChange > 20 || windSpeedChange > 5 || previous.description != current.description
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
        distanceAndTimeLabel.frame = CGRect(x: 38, y: 15, width: 140, height: 30)
        routeInfoView.addSubview(distanceAndTimeLabel)
        
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = UIColor(hex: "#40cbd8")
        closeButton.frame = CGRect(x: routeInfoView.frame.width - 32, y: 12, width: 24, height: 24)
        closeButton.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            if let overlayToRemove = mapView.overlays.first(where: { overlay in
                guard let polyline = overlay as? MKPolyline,
                      let userInfo = polyline.userInfo as? [String: Any],
                      let overlayIndex = userInfo["index"] as? Int else { return false }
                return overlayIndex == index
            }) {
                mapView.removeOverlay(overlayToRemove)
                let annotationsToRemove = mapView.annotations.filter { annotation in
                    guard let weatherAnnotation = annotation as? MapPage.WeatherAnnotation else { return false }
                    return weatherAnnotation.routeIndex == index
                }
                mapView.removeAnnotations(annotationsToRemove)
            }
            routeInfoView.removeFromSuperview()
            if let viewIndex = self.routeInfoViews.firstIndex(of: routeInfoView) {
                self.routeInfoViews.remove(at: viewIndex)
            }
            
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
        guard let selectedView = sender.view,
              let mapView = selectedView.superview?.subviews.compactMap({ $0 as? MKMapView }).first else { return }
        
        let selectedIndex = selectedView.tag
        
        let overlaysToRemove = mapView.overlays.filter { overlay in
            if let polyline = overlay as? MKPolyline,
               let userInfo = polyline.userInfo as? [String: Any],
               let index = userInfo["index"] as? Int {
                return index != selectedIndex
            }
            return true
        }
        
        for overlay in overlaysToRemove {
            if let polyline = overlay as? MKPolyline,
               let routeIndex = Int(polyline.title ?? "") {
                let annotationsToRemove = mapView.annotations.filter { annotation in
                    guard let weatherAnnotation = annotation as? MapPage.WeatherAnnotation else { return false }
                    return weatherAnnotation.routeIndex == routeIndex
                }
                mapView.removeAnnotations(annotationsToRemove)
            }
            mapView.removeOverlay(overlay)
        }
        
        var indicesToRemove: [Int] = []
        for (index, view) in routeInfoViews.enumerated() {
            if view.tag != selectedIndex {
                view.removeFromSuperview()
                indicesToRemove.append(index)
            } else {
                UIView.animate(withDuration: 0.3) {
                    view.frame = CGRect(x: 10, y: 70, width: view.frame.width, height: view.frame.height)
                }
            }
        }
        
        for index in indicesToRemove.reversed() {
            routeInfoViews.remove(at: index)
        }
        
        if let selectedRoute = currentRoute {
            mapView.setVisibleMapRect(selectedRoute.polyline.boundingMapRect, animated: true)
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last,
              let route = currentRoute,
              let lastLocation = lastWeatherUpdateLocation,
              let mapView = mapViewReference else { return }
        
        let distanceFromLastUpdate = currentLocation.distance(from: lastLocation) / 1000.0
        distanceTraveled += distanceFromLastUpdate
        
        if distanceTraveled >= updateDistanceThreshold {
            updateWeatherAnnotationsAlongRoute(route: route, in: mapView)
            distanceTraveled = 0.0
            lastWeatherUpdateLocation = currentLocation
        } else {
            lastWeatherUpdateLocation = currentLocation
        }
    }
    
    private func updateWeatherAnnotationsAlongRoute(route: MKRoute, in mapView: MKMapView) {
        let polyline = route.polyline
        let pointCount = polyline.pointCount
        let numberOfAnnotations = 5
        let intervalPoints = pointCount / (numberOfAnnotations - 1)
        
        let routeIndex = Int(polyline.title ?? "0") ?? 0
        let annotationsToRemove = mapView.annotations.filter { annotation in
            guard let weatherAnnotation = annotation as? MapPage.WeatherAnnotation else { return false }
            return weatherAnnotation.routeIndex == routeIndex
        }
        mapView.removeAnnotations(annotationsToRemove)
        
        var previousWeatherData: WeatherData? = nil
        
        for i in 0..<numberOfAnnotations {
            let pointIndex = i * intervalPoints
            let coordinate = polyline.points()[min(pointIndex, pointCount - 1)].coordinate
            
            fetchWeatherAndAddAnnotation(coordinate: coordinate, mapView: mapView, routeIndex: routeIndex) { weatherData in
                if let prevWeather = previousWeatherData, let newWeather = weatherData {
                    if self.isSignificantWeatherChange(previous: prevWeather, current: newWeather) {
                        let annotation = MapPage.WeatherAnnotation(coordinate: coordinate, weatherData: newWeather, routeIndex: routeIndex)
                        DispatchQueue.main.async {
                            mapView.addAnnotation(annotation)
                        }
                    }
                }
                previousWeatherData = weatherData
            }
        }
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let weatherAnnotation = annotation as? MapPage.WeatherAnnotation else { return nil }
        
        let identifier = "WeatherAnnotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }
        
        let weatherDesc = weatherAnnotation.weatherData.description.lowercased()
        switch weatherDesc {
        case let str where str.contains("clear"):
            annotationView?.image = UIImage(systemName: "sun.max.fill")?.withTintColor(.yellow)
        case let str where str.contains("cloud"):
            annotationView?.image = UIImage(systemName: "cloud.fill")?.withTintColor(.gray)
        case let str where str.contains("rain"):
            annotationView?.image = UIImage(systemName: "cloud.rain.fill")?.withTintColor(.blue)
        case let str where str.contains("snow"):
            annotationView?.image = UIImage(systemName: "snowflake")?.withTintColor(.white)
        case let str where str.contains("night"):
            annotationView?.image = UIImage(systemName: "moon.fill")?.withTintColor(.purple)
        default:
            annotationView?.image = UIImage(systemName: "cloud.fill")?.withTintColor(.gray)
        }
        
        annotationView?.frame.size = CGSize(width: 30, height: 30)
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline,
           let userInfo = polyline.userInfo as? [String: Any],
           let isShortest = userInfo["isShortest"] as? Bool {
            
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = isShortest ? .blue : UIColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 1.0)
            renderer.lineWidth = 5.0
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
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

