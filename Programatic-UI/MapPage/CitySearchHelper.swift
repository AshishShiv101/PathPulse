import MapKit
import CoreLocation



class WeatherAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let weatherData: WeatherData
    let routeIndex: Int
    
    var title: String? {
        return weatherData.description.capitalized
    }
    
    var subtitle: String? {
        return String(format: "%.1f°C", weatherData.temperature)
    }
    
    init(coordinate: CLLocationCoordinate2D, weatherData: WeatherData, routeIndex: Int) {
        self.coordinate = coordinate
        self.weatherData = weatherData
        self.routeIndex = routeIndex
        super.init()
    }
}

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
        return distanceInMeters / 1000.0
    }
    
    private func setupMapDelegate(for mapView: MKMapView) {
        mapView.delegate = self
        mapViewReference = mapView
    }
    
    private func calculateRoute(from startCoordinate: CLLocationCoordinate2D, to destinationCoordinate: CLLocationCoordinate2D, mapView: MKMapView) {
        setupMapDelegate(for: mapView)
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations.filter { $0 is WeatherAnnotation })
        
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
        let intervalPoints = max(pointCount / (numberOfAnnotations - 1), 1)
        var previousWeatherData: WeatherData? = nil
        for i in 0..<numberOfAnnotations {
            let pointIndex = min(i * intervalPoints, pointCount - 1)
            let coordinate = polyline.points()[pointIndex].coordinate
            fetchWeatherAndAddAnnotation(coordinate: coordinate, mapView: mapView, routeIndex: routeIndex) { weatherData in
                if let weatherData = weatherData {
                    if let prevWeather = previousWeatherData {
                        if self.isSignificantWeatherChange(previous: prevWeather, current: weatherData) {
                            let annotation = WeatherAnnotation(coordinate: coordinate, weatherData: weatherData, routeIndex: routeIndex)
                            DispatchQueue.main.async {
                                mapView.addAnnotation(annotation)
                            }
                        }
                    } else {
                        let annotation = WeatherAnnotation(coordinate: coordinate, weatherData: weatherData, routeIndex: routeIndex)
                        DispatchQueue.main.async {
                            mapView.addAnnotation(annotation)
                        }
                    }
                    previousWeatherData = weatherData
                }
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
        routeInfoView.backgroundColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0)
        routeInfoView.layer.cornerRadius = 12
        routeInfoView.layer.shadowColor = UIColor.black.cgColor
        routeInfoView.layer.shadowOpacity = 0.5
        routeInfoView.layer.shadowOffset = CGSize(width: 0, height: 4)
        routeInfoView.layer.shadowRadius = 8
        routeInfoView.layer.borderWidth = 2
        routeInfoView.layer.borderColor = isShortest ? UIColor.blue.cgColor : UIColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 1).cgColor
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
        closeButton.tintColor = UIColor(red: 0.25, green: 0.80, blue: 0.85, alpha: 1.0)
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
                    guard let weatherAnnotation = annotation as? WeatherAnnotation else { return false }
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
              let mapView = mapViewReference else { return }
        
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
                    guard let weatherAnnotation = annotation as? WeatherAnnotation else { return false }
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
        }
        lastWeatherUpdateLocation = currentLocation
    }
    
    private func updateWeatherAnnotationsAlongRoute(route: MKRoute, in mapView: MKMapView) {
        let polyline = route.polyline
        let pointCount = polyline.pointCount
        let numberOfAnnotations = 5
        let intervalPoints = max(pointCount / (numberOfAnnotations - 1), 1)
        
        let routeIndex = Int(polyline.title ?? "0") ?? 0
        let annotationsToRemove = mapView.annotations.filter { annotation in
            guard let weatherAnnotation = annotation as? WeatherAnnotation else { return false }
            return weatherAnnotation.routeIndex == routeIndex
        }
        mapView.removeAnnotations(annotationsToRemove)
        
        var previousWeatherData: WeatherData? = nil
        
        for i in 0..<numberOfAnnotations {
            let pointIndex = min(i * intervalPoints, pointCount - 1)
            let coordinate = polyline.points()[pointIndex].coordinate
            
            fetchWeatherAndAddAnnotation(coordinate: coordinate, mapView: mapView, routeIndex: routeIndex) { weatherData in
                if let weatherData = weatherData {
                    if let prevWeather = previousWeatherData {
                        if self.isSignificantWeatherChange(previous: prevWeather, current: weatherData) {
                            let annotation = WeatherAnnotation(coordinate: coordinate, weatherData: weatherData, routeIndex: routeIndex)
                            DispatchQueue.main.async {
                                mapView.addAnnotation(annotation)
                            }
                        }
                    } else {
                        let annotation = WeatherAnnotation(coordinate: coordinate, weatherData: weatherData, routeIndex: routeIndex)
                        DispatchQueue.main.async {
                            mapView.addAnnotation(annotation)
                        }
                    }
                    previousWeatherData = weatherData
                }
            }
        }
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let weatherAnnotation = annotation as? WeatherAnnotation else { return nil }
        
        let identifier = "WeatherAnnotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            
            let detailLabel = UILabel()
            detailLabel.numberOfLines = 0
            detailLabel.font = .systemFont(ofSize: 12)
            detailLabel.text = String(format: "Humidity: %.0f%%\nWind: %.1f m/s",
                                    weatherAnnotation.weatherData.humidity,
                                    weatherAnnotation.weatherData.windSpeed)
            annotationView?.detailCalloutAccessoryView = detailLabel
        } else {
            annotationView?.annotation = annotation
        }
        
        let imageSize = CGSize(width: 30, height: 30)
        let gradientImage = createGradientIcon(
            for: weatherAnnotation.weatherData.description.lowercased(),
            temperature: weatherAnnotation.weatherData.temperature,
            size: imageSize
        )
        annotationView?.image = gradientImage ?? UIImage(systemName: "questionmark.circle")
        annotationView?.frame.size = imageSize
        
        return annotationView
    }
    
    private func createGradientIcon(for condition: String, temperature: Double, size: CGSize) -> UIImage? {
        let imageName: String
        var gradientColors: [CGColor]
        
        // Determine icon based on weather condition
        switch condition.lowercased() {
        case let str where str.contains("wind"):
            imageName = "wind"
            gradientColors = [
                UIColor(red: 0.75, green: 0.85, blue: 0.95, alpha: 1.0).cgColor, // Light sky blue
                UIColor(red: 0.45, green: 0.65, blue: 0.85, alpha: 1.0).cgColor  // Soft blue
            ]
        case let str where str.contains("rain") || str.contains("shower"):
            imageName = "cloud.rain.fill"
            gradientColors = [
                UIColor(red: 0.40, green: 0.55, blue: 0.70, alpha: 1.0).cgColor, // Steel blue
                UIColor(red: 0.15, green: 0.25, blue: 0.45, alpha: 1.0).cgColor  // Deep blue
            ]
        case let str where str.contains("snow"):
            imageName = "snowflake"
            gradientColors = [
                UIColor(red: 0.95, green: 0.95, blue: 1.00, alpha: 1.0).cgColor, // Almost white
                UIColor(red: 0.70, green: 0.80, blue: 0.95, alpha: 1.0).cgColor  // Light icy blue
            ]
        case let str where str.contains("thunder") || str.contains("storm"):
            imageName = "cloud.bolt.fill"
            gradientColors = [
                UIColor(red: 0.60, green: 0.60, blue: 0.70, alpha: 1.0).cgColor, // Stormy gray
                UIColor(red: 0.30, green: 0.30, blue: 0.45, alpha: 1.0).cgColor  // Dark storm blue
            ]
        case let str where str.contains("sun") || str.contains("clear"):
            imageName = "sun.max.fill"
            gradientColors = [
                UIColor(red: 1.00, green: 0.90, blue: 0.50, alpha: 1.0).cgColor, // Bright yellow
                UIColor(red: 1.00, green: 0.60, blue: 0.20, alpha: 1.0).cgColor  // Warm orange
            ]
        case let str where str.contains("cloud"):
            imageName = "cloud.fill"
            gradientColors = [
                UIColor(red: 0.80, green: 0.85, blue: 0.90, alpha: 1.0).cgColor, // Light gray-blue
                UIColor(red: 0.55, green: 0.65, blue: 0.75, alpha: 1.0).cgColor  // Medium gray-blue
            ]
        default:
            imageName = "cloud.fill"
            gradientColors = [
                UIColor(red: 0.70, green: 0.75, blue: 0.80, alpha: 1.0).cgColor, // Light neutral gray
                UIColor(red: 0.50, green: 0.55, blue: 0.60, alpha: 1.0).cgColor  // Medium neutral gray
            ]
        }
        
        // Adjust gradient based on temperature
        let tempAdjustedColors = adjustGradientForTemperature(gradientColors, temperature: temperature)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        guard let baseImage = UIImage(systemName: imageName)?.withRenderingMode(.alwaysTemplate) else {
            UIGraphicsEndImageContext()
            return nil
        }
        
        let config = UIImage.SymbolConfiguration(pointSize: size.height)
        let templateImage = baseImage.applyingSymbolConfiguration(config)
        
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(origin: .zero, size: size)
        gradient.colors = tempAdjustedColors
        gradient.startPoint = CGPoint(x: 0.5, y: 1) // Bottom to top
        gradient.endPoint = CGPoint(x: 0.5, y: 0)
        
        guard let maskImage = templateImage?.cgImage else {
            UIGraphicsEndImageContext()
            return nil
        }
        
        context.saveGState()
        context.clip(to: CGRect(origin: .zero, size: size), mask: maskImage)
        gradient.render(in: context)
        context.restoreGState()
        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return finalImage
    }
    
    private func adjustGradientForTemperature(_ baseColors: [CGColor], temperature: Double) -> [CGColor] {
        var adjustedColors = baseColors
        
        // Temperature-based adjustments
        let warmthFactor: CGFloat = min(max((temperature - 10.0) / 40.0, 0.0), 1.0) // Normalizes between 10°C and 50°C
        let coldFactor: CGFloat = min(max((10.0 - temperature) / 20.0, 0.0), 1.0)  // Normalizes between -10°C and 10°C
        
        if temperature < 10.0 {
            // Add blue tint for cold temperatures
            if let topColor = baseColors.first?.components,
               let bottomColor = baseColors.last?.components {
                let adjustedTop = UIColor(
                    red: max(topColor[0] - coldFactor * 0.2, 0.0),
                    green: max(topColor[1] - coldFactor * 0.1, 0.0),
                    blue: min(topColor[2] + coldFactor * 0.2, 1.0),
                    alpha: topColor[3]
                )
                let adjustedBottom = UIColor(
                    red: max(bottomColor[0] - coldFactor * 0.3, 0.0),
                    green: max(bottomColor[1] - coldFactor * 0.2, 0.0),
                    blue: min(bottomColor[2] + coldFactor * 0.3, 1.0),
                    alpha: bottomColor[3]
                )
                adjustedColors = [adjustedTop.cgColor, adjustedBottom.cgColor]
            }
        } else if temperature > 20.0 {
            // Add warm tint for high temperatures
            if let topColor = baseColors.first?.components,
               let bottomColor = baseColors.last?.components {
                let adjustedTop = UIColor(
                    red: min(topColor[0] + warmthFactor * 0.3, 1.0),
                    green: max(topColor[1] - warmthFactor * 0.2, 0.0),
                    blue: max(topColor[2] - warmthFactor * 0.3, 0.0),
                    alpha: topColor[3]
                )
                let adjustedBottom = UIColor(
                    red: min(bottomColor[0] + warmthFactor * 0.4, 1.0),
                    green: max(bottomColor[1] - warmthFactor * 0.3, 0.0),
                    blue: max(bottomColor[2] - warmthFactor * 0.4, 0.0),
                    alpha: bottomColor[3]
                )
                adjustedColors = [adjustedTop.cgColor, adjustedBottom.cgColor]
            }
        }
        
        return adjustedColors
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
