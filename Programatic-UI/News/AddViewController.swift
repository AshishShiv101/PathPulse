import UIKit
import WebKit
import CoreLocation
struct NewsResponse: Decodable {
    let articles: [NewsDataModel]
}
struct NewsDataModel: Decodable {
    let headline: String
    let link: String
    let imageUrl: String?
    let publisher: String
    let publishedAt: String
    
    enum CodingKeys: String, CodingKey {
        case headline = "title"
        case link = "url"
        case imageUrl = "urlToImage"
        case publisher = "source"
        case publishedAt
    }
    enum SourceCodingKeys: String, CodingKey {
        case name
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        headline = try container.decode(String.self, forKey: .headline)
        link = try container.decode(String.self, forKey: .link)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        publishedAt = try container.decode(String.self, forKey: .publishedAt)
        
        let sourceContainer = try container.nestedContainer(keyedBy: SourceCodingKeys.self, forKey: .publisher)
        publisher = try sourceContainer.decode(String.self, forKey: .name)
    }
}
class NewsViewController: UIViewController, CLLocationManagerDelegate, UIScrollViewDelegate {
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let titleLabel = UILabel()
    private let cityLabel = UILabel()
    private let buttonStackView = UIStackView()
    private let locationManager = CLLocationManager()
    private var currentLocation: String?
    private var currentCoordinates: CLLocation?
    private var readArticles: Set<String> = Set()
    private var newsArticles: [NewsDataModel] = []
    private let filterButton = UIButton()
    private let showMoreButton = UIButton()
    private var displayedArticleCount = 0
    private let articlesPerPage = 20
    private var currentQuery: String?
    private let noNewsLabel = UILabel()
    
    public var searchedCity: String? {
        didSet {
            updateCityLabel()
            if searchedCity != nil {
                fetchNewsForSearchedCity()
            }
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setGradientBackground()
        scrollView.delegate = self
        setupLocationManager()
        if let searchedCity = searchedCity {
            fetchNewsForSearchedCity()
        }
    }
    
    // MARK: - Setup Methods
    private func setupView() {
        let backButton = UIButton()
        let backImage = UIImage(systemName: "chevron.left")
        backButton.setImage(backImage, for: .normal)
        backButton.tintColor = .white
        backButton.layer.cornerRadius = 10
        backButton.clipsToBounds = true
        backButton.addTarget(self, action: #selector(dismissDetailView), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Latest News Updates"
        titleLabel.textColor = .white
        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        
        cityLabel.translatesAutoresizingMaskIntoConstraints = false
        cityLabel.textColor = .white
        cityLabel.font = .systemFont(ofSize: 16, weight: .regular)
        cityLabel.textAlignment = .center
        cityLabel.text = searchedCity ?? currentLocation ?? "City"
        view.addSubview(cityLabel)
        
        filterButton.translatesAutoresizingMaskIntoConstraints = false
        let filterImage = UIImage(systemName: "line.3.horizontal.decrease.circle")
        filterButton.setImage(filterImage, for: .normal)
        filterButton.tintColor = .white
        filterButton.addTarget(self, action: #selector(showFilterOptions), for: .touchUpInside)
        view.addSubview(filterButton)
        
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 12
        buttonStackView.alignment = .center
        buttonStackView.distribution = .fillEqually
        view.addSubview(buttonStackView)
        
        let buttonTitles = ["General News", "Weather"]
        for (index, title) in buttonTitles.enumerated() {
            let button = createStyledButton(title: title, isSelected: index == 0)
            button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
            buttonStackView.addArrangedSubview(button)
        }
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        view.addSubview(scrollView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        stackView.distribution = .fill
        scrollView.addSubview(stackView)
        
        noNewsLabel.translatesAutoresizingMaskIntoConstraints = false
        noNewsLabel.text = "No news available at this time"
        noNewsLabel.textColor = .white
        noNewsLabel.font = .systemFont(ofSize: 16, weight: .regular)
        noNewsLabel.textAlignment = .center
        noNewsLabel.isHidden = true
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60),
            titleLabel.trailingAnchor.constraint(equalTo: filterButton.leadingAnchor, constant: -20),
            titleLabel.heightAnchor.constraint(equalToConstant: 40),
            
            cityLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            cityLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cityLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cityLabel.heightAnchor.constraint(equalToConstant: 20),
            
            filterButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            filterButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            filterButton.widthAnchor.constraint(equalToConstant: 40),
            filterButton.heightAnchor.constraint(equalToConstant: 40),
            
            buttonStackView.topAnchor.constraint(equalTo: cityLabel.bottomAnchor, constant: 12),
            buttonStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStackView.heightAnchor.constraint(equalToConstant: 40),
            buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            scrollView.topAnchor.constraint(equalTo: buttonStackView.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func createStyledButton(title: String, isSelected: Bool) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = isSelected ? UIColor(hex: "#40cbd8") : UIColor(hex: "#555555")
        config.baseForegroundColor = isSelected ? .black : .white
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        
        let button = UIButton(configuration: config, primaryAction: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        
        // Add subtle shadow for iOS-like elevation
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        
        return button
    }
    
    func setGradientBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor(hex: "#222222").cgColor, UIColor(hex: "#222222").cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        if searchedCity == nil {
            locationManager.startUpdatingLocation()
        }
    }
    
    // MARK: - Location Manager Delegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard searchedCity == nil, let location = locations.last else { return }
        
        currentCoordinates = location
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let self = self, let placemark = placemarks?.first else { return }
            guard self.searchedCity == nil else { return }
            
            if let city = placemark.locality {
                self.currentLocation = city
                print("Current location: \(city)")
                let initialQuery = "\"\(city)\" (\"road accident\" OR \"traffic jam\" OR \"road closure\" OR \"protest\" OR \"riot\" OR \"strike\" OR \"public event\" OR \"festival\" OR \"parade\" OR \"construction\" OR \"bridge collapse\" OR \"train derailment\" OR \"flight delay\" OR \"airport closure\" OR \"natural disaster\" OR \"flood\" OR \"earthquake\" OR \"landslide\")"
                self.currentQuery = initialQuery
                DispatchQueue.main.async {
                    self.cityLabel.text = city
                }
                self.fetchNewsData(query: initialQuery, fromDate: nil, toDate: nil) { success in
                    if !success {
                        self.fetchNewsForNearbyCities(location: location, originalCity: city)
                    }
                }
            } else {
                self.fetchNewsForNearbyRenownedCity(location: location)
            }
        }
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - Fetch News for Searched City
    private func fetchNewsForSearchedCity() {
        guard let searchedCity = searchedCity else { return }
        
        locationManager.stopUpdatingLocation()
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(searchedCity) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            if let placemark = placemarks?.first, let location = placemark.location {
                self.currentCoordinates = location
                let city = placemark.locality ?? placemark.administrativeArea ?? placemark.country ?? searchedCity
                let initialQuery = "\"\(city)\" (\"road accident\" OR \"traffic jam\" OR \"road closure\" OR \"protest\" OR \"riot\" OR \"strike\" OR \"public event\" OR \"festival\" OR \"parade\" OR \"construction\" OR \"bridge collapse\" OR \"train derailment\" OR \"flight delay\" OR \"airport closure\" OR \"natural disaster\" OR \"flood\" OR \"earthquake\" OR \"landslide\")"
                self.currentQuery = initialQuery
                DispatchQueue.main.async {
                    self.cityLabel.text = searchedCity
                }
                self.fetchNewsData(query: initialQuery, fromDate: nil, toDate: nil) { success in
                    if !success {
                        print("No news found for searched city: \(searchedCity)")
                        self.fetchNewsForNearbyCities(location: location, originalCity: searchedCity)
                    }
                }
            } else {
                let fallbackQuery = "\"\(searchedCity)\" (\"road accident\" OR \"traffic jam\" OR \"road closure\" OR \"protest\" OR \"riot\" OR \"strike\" OR \"public event\" OR \"festival\" OR \"parade\" OR \"construction\" OR \"bridge collapse\" OR \"train derailment\" OR \"flight delay\" OR \"airport closure\" OR \"natural disaster\" OR \"flood\" OR \"earthquake\" OR \"landslide\")"
                self.currentQuery = fallbackQuery
                self.fetchNewsData(query: fallbackQuery, fromDate: nil, toDate: nil) { success in
                    if !success {
                        print("No news found for searched city: \(searchedCity), attempting nearby cities")
                        self.fetchCoordinatesForSearchedCity(searchedCity)
                    }
                }
            }
        }
    }
    
    private func fetchCoordinatesForSearchedCity(_ city: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(city) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            if let placemark = placemarks?.first, let location = placemark.location {
                self.currentCoordinates = location
                self.fetchNewsForNearbyCities(location: location, originalCity: city)
            } else {
                print("Could not find coordinates for \(city)")
            }
        }
    }
    
    private func fetchNewsForNearbyCities(location: CLLocation, originalCity: String) {
        let distanceInMeters: Double = 50_000
        let earthRadius: Double = 6_371_000
        
        let offsets = [
            (latOffset: distanceInMeters / earthRadius * (180 / .pi), lonOffset: 0.0),
            (latOffset: -distanceInMeters / earthRadius * (180 / .pi), lonOffset: 0.0),
            (latOffset: 0.0, lonOffset: distanceInMeters / (earthRadius * cos(location.coordinate.latitude * .pi / 180)) * (180 / .pi)),
            (latOffset: 0.0, lonOffset: -distanceInMeters / (earthRadius * cos(location.coordinate.latitude * .pi / 180)) * (180 / .pi))
        ]
        
        var nearbyCities: Set<String> = []
        let dispatchGroup = DispatchGroup()
        
        for offset in offsets {
            let nearbyLocation = CLLocation(
                latitude: location.coordinate.latitude + offset.latOffset,
                longitude: location.coordinate.longitude + offset.lonOffset
            )
            
            dispatchGroup.enter()
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(nearbyLocation) { [weak self] (placemarks, error) in
                guard let self = self, let placemark = placemarks?.first else {
                    dispatchGroup.leave()
                    return
                }
                
                if let nearbyCity = placemark.locality, nearbyCity.lowercased() != originalCity.lowercased() {
                    nearbyCities.insert(nearbyCity)
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            if nearbyCities.isEmpty {
                print("No nearby cities found within 50 km of \(originalCity)")
                self.fetchNewsForNearbyRenownedCity(location: location)
                return
            }
            
            var newsFound = false
            let nearbyCitiesArray = Array(nearbyCities)
            var currentIndex = 0
            
            func tryNextCity() {
                guard currentIndex < nearbyCitiesArray.count else {
                    if !newsFound {
                        print("No news found for nearby cities, falling back to broader region")
                        self.fetchNewsForNearbyRenownedCity(location: location)
                    }
                    return
                }
                
                let nearbyCity = nearbyCitiesArray[currentIndex]
                let nearbyQuery = "\"\(nearbyCity)\" (\"road accident\" OR \"traffic jam\" OR \"road closure\" OR \"protest\" OR \"riot\" OR \"strike\" OR \"public event\" OR \"festival\" OR \"parade\" OR \"construction\" OR \"bridge collapse\" OR \"train derailment\" OR \"flight delay\" OR \"airport closure\" OR \"natural disaster\" OR \"flood\" OR \"earthquake\" OR \"landslide\")"
                self.currentQuery = nearbyQuery
                DispatchQueue.main.async {
                    self.cityLabel.text = "\(originalCity) (near \(nearbyCity))"
                }
                self.fetchNewsData(query: nearbyQuery, fromDate: nil, toDate: nil) { success in
                    if success {
                        newsFound = true
                    } else {
                        currentIndex += 1
                        tryNextCity()
                    }
                }
            }
            tryNextCity()
        }
    }
    
    private func fetchNewsForNearbyRenownedCity(location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let self = self, let placemark = placemarks?.first else { return }
            
            let fallbackLocation = placemark.administrativeArea ?? placemark.country ?? "Unknown"
            print("Fallback location: \(fallbackLocation)")
            let fallbackQuery = "\"\(fallbackLocation)\" (\"road accident\" OR \"traffic jam\" OR \"road closure\" OR \"protest\" OR \"riot\" OR \"strike\" OR \"public event\" OR \"festival\" OR \"parade\" OR \"construction\" OR \"bridge collapse\" OR \"train derailment\" OR \"flight delay\" OR \"airport closure\" OR \"natural disaster\" OR \"flood\" OR \"earthquake\" OR \"landslide\")"
            self.currentQuery = fallbackQuery
            DispatchQueue.main.async {
                self.cityLabel.text = fallbackLocation
            }
            self.fetchNewsData(query: fallbackQuery, fromDate: nil, toDate: nil) { success in
                if !success {
                    print("No news found for fallback location: \(fallbackLocation)")
                    DispatchQueue.main.async {
                        self.showNoNewsMessage()
                    }
                }
            }
        }
    }
    
    // MARK: - Fetch News Data
    private func fetchNewsData(query: String, fromDate: String?, toDate: String?, completion: @escaping (Bool) -> Void) {
        let apiKey = "30e36402849c414a9a78de022db36455"
        var urlString = "https://newsapi.org/v2/everything?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)&apiKey=\(apiKey)&language=en&sortBy=relevancy"
        
        if let from = fromDate {
            urlString += "&from=\(from)"
        }
        if let to = toDate {
            urlString += "&to=\(to)"
        }
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            completion(false)
            return
        }
        
        print("Fetching news with URL: \(urlString)")
        
        let session = URLSession.shared
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else {
                completion(false)
                return
            }
            
            if let error = error {
                print("Error fetching news: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.showNoNewsMessage()
                }
                completion(false)
                return
            }
            
            guard let data = data else {
                print("No data received")
                DispatchQueue.main.async {
                    self.showNoNewsMessage()
                }
                completion(false)
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(NewsResponse.self, from: data)
                let filteredArticles = self.filterRelevantArticles(response.articles, query: query, fromDate: fromDate)
                DispatchQueue.main.async {
                    self.updateNewsData(with: filteredArticles)
                    if filteredArticles.isEmpty {
                        self.showNoNewsMessage()
                    } else {
                        self.hideNoNewsMessage()
                    }
                    completion(!filteredArticles.isEmpty)
                }
            } catch {
                print("Error parsing JSON: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw JSON: \(jsonString)")
                }
                DispatchQueue.main.async {
                    self.showNoNewsMessage()
                }
                completion(false)
            }
        }
        task.resume()
    }
    
    private func filterRelevantArticles(_ articles: [NewsDataModel], query: String, fromDate: String?) -> [NewsDataModel] {
        let dateFormatter = ISO8601DateFormatter()
        let queryComponents = query.lowercased().components(separatedBy: " ")
        guard let locationComponent = queryComponents.first(where: { $0.hasPrefix("\"") && $0.hasSuffix("\"") }) else {
            return []
        }
        let location = String(locationComponent.dropFirst().dropLast()).lowercased()
        
        return articles.filter { article in
            let title = article.headline.lowercased()
            let publisher = article.publisher.lowercased()
            let containsLocation = title.contains(location) || publisher.contains(location)
            
            if !containsLocation {
                return false
            }
            
            let containsQueryTerms = queryComponents.dropFirst().contains { term in
                title.contains(term.replacingOccurrences(of: "\"", with: ""))
            }
            
            if let from = fromDate,
               let articleDate = dateFormatter.date(from: article.publishedAt),
               let fromDateObj = dateFormatter.date(from: from + "T00:00:00Z") {
                return containsQueryTerms && articleDate >= fromDateObj
            }
            return containsQueryTerms
        }
    }
    
    private func updateNewsData(with newData: [NewsDataModel]) {
        let validArticles = newData.filter { !$0.headline.isEmpty && !$0.link.isEmpty && $0.imageUrl != nil }
        newsArticles = validArticles
        displayedArticleCount = 0
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        displayNextArticles()
    }
    
    private func displayNextArticles() {
        let startIndex = displayedArticleCount
        let endIndex = min(startIndex + articlesPerPage, newsArticles.count)
        
        for i in startIndex..<endIndex {
            let newsCard = createNewsCard(newsData: newsArticles[i])
            stackView.addArrangedSubview(newsCard)
        }
        displayedArticleCount = endIndex
        showMoreButton.removeFromSuperview()
        if displayedArticleCount < newsArticles.count {
            setupShowMoreButton()
            stackView.addArrangedSubview(showMoreButton)
        }
        
        if newsArticles.isEmpty {
            showNoNewsMessage()
        } else {
            hideNoNewsMessage()
        }
    }
    
    private func setupShowMoreButton() {
        showMoreButton.translatesAutoresizingMaskIntoConstraints = false
        showMoreButton.setTitle("Show More", for: .normal)
        showMoreButton.setTitleColor(.black, for: .normal)
        showMoreButton.backgroundColor = UIColor(hex: "#40cbd8")
        showMoreButton.layer.cornerRadius = 8
        showMoreButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        showMoreButton.addTarget(self, action: #selector(showMoreTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            showMoreButton.heightAnchor.constraint(equalToConstant: 44),
            showMoreButton.widthAnchor.constraint(equalToConstant: 120)
        ])
    }
    
    // MARK: - No News Message
    private func showNoNewsMessage() {
        if noNewsLabel.superview == nil {
            scrollView.addSubview(noNewsLabel)
            NSLayoutConstraint.activate([
                noNewsLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
                noNewsLabel.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor)
            ])
        }
        noNewsLabel.isHidden = false
    }
    
    private func hideNoNewsMessage() {
        noNewsLabel.isHidden = true
    }
    
    // MARK: - Actions
    @objc private func showMoreTapped() {
        displayNextArticles()
    }
    
    @objc private func showFilterOptions() {
        let alertController = UIAlertController(title: "Sort News", message: nil, preferredStyle: .actionSheet)
        
        let ascendingAction = UIAlertAction(title: "Time Posted (Ascending)", style: .default) { [weak self] _ in
            self?.sortNewsByTimeAscending()
        }
        let descendingAction = UIAlertAction(title: "Time Posted (Descending)", style: .default) { [weak self] _ in
            self?.sortNewsByTimeDescending()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(ascendingAction)
        alertController.addAction(descendingAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    private func sortNewsByTimeAscending() {
        let dateFormatter = ISO8601DateFormatter()
        newsArticles.sort { article1, article2 in
            guard let date1 = dateFormatter.date(from: article1.publishedAt),
                  let date2 = dateFormatter.date(from: article2.publishedAt) else {
                return article1.publishedAt < article2.publishedAt
            }
            return date1 < date2
        }
        updateNewsDisplay()
    }
    
    private func sortNewsByTimeDescending() {
        let dateFormatter = ISO8601DateFormatter()
        newsArticles.sort { article1, article2 in
            guard let date1 = dateFormatter.date(from: article1.publishedAt),
                  let date2 = dateFormatter.date(from: article2.publishedAt) else {
                return article1.publishedAt > article2.publishedAt
            }
            return date1 > date2
        }
        updateNewsDisplay()
    }
    
    private func updateNewsDisplay() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        displayedArticleCount = 0
        displayNextArticles()
    }
    
    @objc private func dismissDetailView() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func buttonPressed(sender: UIButton) {
        buttonStackView.arrangedSubviews.forEach { view in
            if let button = view as? UIButton {
                var config = button.configuration ?? UIButton.Configuration.filled()
                config.baseBackgroundColor = UIColor(hex: "#555555")
                config.baseForegroundColor = .white
                button.configuration = config
                button.layer.shadowOpacity = 0.2 // Reset shadow for unselected
            }
        }
        
        var selectedConfig = sender.configuration ?? UIButton.Configuration.filled()
        selectedConfig.baseBackgroundColor = UIColor(hex: "#40cbd8")
        selectedConfig.baseForegroundColor = .black
        sender.configuration = selectedConfig
        sender.layer.shadowOpacity = 0.4 // Slightly stronger shadow for selected
        
        guard let buttonIndex = buttonStackView.arrangedSubviews.firstIndex(of: sender),
              let location = searchedCity ?? currentLocation else {
            print("Location not available yet.")
            return
        }
        
        var query = ""
        
        switch buttonIndex {
        case 0: // General News (Travel Disruptions)
            query = "\"\(location)\" (\"road accident\" OR \"traffic jam\" OR \"road closure\" OR \"protest\" OR \"riot\" OR \"strike\" OR \"public event\" OR \"festival\" OR \"parade\" OR \"construction\" OR \"bridge collapse\" OR \"train derailment\" OR \"flight delay\" OR \"airport closure\" OR \"natural disaster\" OR \"flood\" OR \"earthquake\" OR \"landslide\")"
            
        case 1: // Weather
            query = "\"\(location)\" (\"temperature\" OR \"storm\" OR \"precipitation\" OR \"weather forecast\")"
            
        default:
            return
        }
        
        guard !query.isEmpty else { return }
        
        currentQuery = query
        fetchNewsData(query: query, fromDate: nil, toDate: nil) { [weak self] success in
            guard let self = self else { return }
            if !success && self.currentCoordinates != nil {
                self.fetchNewsForNearbyCities(location: self.currentCoordinates!, originalCity: location)
            }
        }
    }
    
    private func createNewsCard(newsData: NewsDataModel) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = UIColor(hex: "#333333")
        card.layer.cornerRadius = 12
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.2
        card.layer.shadowOffset = CGSize(width: 0, height: 6)
        card.layer.shadowRadius = 6
        card.clipsToBounds = false
        
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 6
        
        if let imageUrl = newsData.imageUrl {
            imageView.loadImage(from: imageUrl)
        }
        
        let contentStack = UIStackView()
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 8
        contentStack.alignment = .leading
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = newsData.headline
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingTail
        
        let infoStack = UIStackView()
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        infoStack.axis = .vertical
        contentStack.spacing = 8
        infoStack.alignment = .leading
        
        let publisherLabel = UILabel()
        publisherLabel.text = newsData.publisher
        publisherLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        publisherLabel.textColor = .lightGray
        
        let timeLabel = UILabel()
        timeLabel.text = formatDate(newsData.publishedAt)
        timeLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        timeLabel.textColor = .lightGray
        
        let readStatusTag = UIView()
        readStatusTag.translatesAutoresizingMaskIntoConstraints = false
        readStatusTag.layer.cornerRadius = 4
        readStatusTag.clipsToBounds = true
        
        let readStatusLabel = UILabel()
        readStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        readStatusLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        readStatusLabel.textAlignment = .center
        
        if readArticles.contains(newsData.link) {
            readStatusTag.backgroundColor = UIColor.systemGray.withAlphaComponent(0.3)
            readStatusLabel.text = "READ"
            readStatusLabel.textColor = .lightGray
        } else {
            readStatusTag.backgroundColor = UIColor(hex: "#40cbd8").withAlphaComponent(1)
            readStatusLabel.text = "NEW"
            readStatusLabel.textColor = .black
        }
        
        readStatusTag.addSubview(readStatusLabel)
        
        let arrowImageView = UIImageView()
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        arrowImageView.image = UIImage(systemName: "chevron.right")
        arrowImageView.tintColor = .white
        arrowImageView.contentMode = .scaleAspectFit
        
        infoStack.addArrangedSubview(publisherLabel)
        infoStack.addArrangedSubview(timeLabel)
        
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(infoStack)
        
        let horizontalStackView = UIStackView(arrangedSubviews: [imageView, contentStack, readStatusTag, arrowImageView])
        horizontalStackView.translatesAutoresizingMaskIntoConstraints = false
        horizontalStackView.axis = .horizontal
        horizontalStackView.spacing = 12
        horizontalStackView.alignment = .center
        horizontalStackView.distribution = .fill
        
        card.addSubview(horizontalStackView)
        
        card.accessibilityValue = newsData.link
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(newsCardTapped(_:)))
        card.addGestureRecognizer(tapGesture)
        card.isUserInteractionEnabled = true
        
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60),
            
            readStatusTag.widthAnchor.constraint(equalToConstant: 40),
            readStatusTag.heightAnchor.constraint(equalToConstant: 20),
            
            readStatusLabel.centerXAnchor.constraint(equalTo: readStatusTag.centerXAnchor),
            readStatusLabel.centerYAnchor.constraint(equalTo: readStatusTag.centerYAnchor),
            
            arrowImageView.widthAnchor.constraint(equalToConstant: 20),
            arrowImageView.heightAnchor.constraint(equalToConstant: 20),
            
            horizontalStackView.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            horizontalStackView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            horizontalStackView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            horizontalStackView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])
        
        return card
    }
    
    @objc private func newsCardTapped(_ sender: UITapGestureRecognizer) {
        guard let card = sender.view,
              let link = card.accessibilityValue,
              let index = stackView.arrangedSubviews.firstIndex(of: card),
              index < newsArticles.count else {
            print("No link associated with this card or invalid index.")
            return
        }
        readArticles.insert(link)
        let newsData = newsArticles[index]
        let updatedCard = createNewsCard(newsData: newsData)
        stackView.removeArrangedSubview(card)
        card.removeFromSuperview()
        stackView.insertArrangedSubview(updatedCard, at: index)
        openArticle(link: link)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        guard let date = dateFormatter.date(from: dateString) else {
            return dateString
        }
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)
        if let minutes = components.minute, minutes < 60 {
            return "\(minutes)m ago"
        } else if let hours = components.hour, hours < 24 {
            return "\(hours)h ago"
        } else if let days = components.day {
            return "\(days)d ago"
        }
        return dateString
    }
    
    private func openArticle(link: String) {
        guard let url = URL(string: link) else {
            print("Invalid URL string: \(link)")
            return
        }
        print("Opening URL: \(url.absoluteString)")
        let webViewController = WebViewController()
        webViewController.urlString = link
        
        if let navigationController = navigationController {
            navigationController.pushViewController(webViewController, animated: true)
        } else {
            present(webViewController, animated: true, completion: nil)
        }
    }
    
    private func updateCityLabel() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.cityLabel.text = self.searchedCity ?? self.currentLocation ?? "City"
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height
        if offsetY > contentHeight - frameHeight - 100 && displayedArticleCount >= articlesPerPage {
            if showMoreButton.superview == nil && displayedArticleCount < newsArticles.count {
                DispatchQueue.main.async { [weak self] in
                    self?.stackView.addArrangedSubview(self?.showMoreButton ?? UIView())
                }
            }
        }
    }
}

extension UIImageView {
    func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        if let cachedImage = ImageNewsCache.shared.getImage(for: url) {
            DispatchQueue.main.async { [weak self] in
                self?.image = cachedImage
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self else { return }
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = image
                }
                ImageNewsCache.shared.saveImage(image, for: url)
            }
        }.resume()
    }
}
