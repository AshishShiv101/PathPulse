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

class NewsViewController: UIViewController, CLLocationManagerDelegate {
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let titleLabel = UILabel()
    private let buttonStackView = UIStackView()
    private let locationManager = CLLocationManager()
    private var currentLocation: String?
    private var readArticles: Set<String> = Set()
    private var newsArticles: [NewsDataModel] = []
    private let filterButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocationManager()
        setupView()
        setGradientBackground()
    }

    func setGradientBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.black.cgColor, UIColor.white.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)  // Top center
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)    // Bottom center
        gradientLayer.frame = view.bounds
        
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let self = self, let placemark = placemarks?.first else { return }
            
            // Get the current city
            if let city = placemark.locality {
                self.currentLocation = city
                print("Current location: \(city)")
                
                // Fetch news for the current city
                self.fetchNewsData(query: "\(city)-road-accident") { [weak self] success in
                    guard let self = self else { return }
                    
                    // If no news is found, fetch news for a nearby renowned city
                    if !success {
                        self.fetchNewsForNearbyRenownedCity(location: location)
                    }
                }
            } else {
                // If no city is found, fetch news for a nearby renowned city
                self.fetchNewsForNearbyRenownedCity(location: location)
            }
        }
        locationManager.stopUpdatingLocation()
    }

    private func fetchNewsForNearbyRenownedCity(location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let self = self, let placemark = placemarks?.first else { return }
            
            // Get the administrative area (state) or country as a fallback
            let fallbackLocation = placemark.administrativeArea ?? placemark.country ?? "Unknown"
            print("Fallback location: \(fallbackLocation)")
            
            // Fetch news for the fallback location
            self.fetchNewsData(query: "\(fallbackLocation)-road-accident") { success in
                if !success {
                    print("No news found for fallback location: \(fallbackLocation)")
                }
            }
        }
    }

    private func fetchNewsData(query: String, completion: @escaping (Bool) -> Void) {
        let apiKey = "30e36402849c414a9a78de022db36455"
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://newsapi.org/v2/everything?q=\(encodedQuery)&apiKey=\(apiKey)") else {
            print("Invalid URL")
            completion(false)
            return
        }
        
        let session = URLSession.shared
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Error fetching news: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let data = data else {
                print("No data received")
                completion(false)
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(NewsResponse.self, from: data)
                DispatchQueue.main.async {
                    self?.updateNewsData(with: response.articles)
                    completion(!response.articles.isEmpty) // Return true if articles are found
                }
            } catch {
                print("Error parsing JSON: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw JSON: \(jsonString)")
                }
                completion(false)
            }
        }
        task.resume()
    }
    
    private func updateNewsData(with newData: [NewsDataModel]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let validArticles = newData.filter { !$0.headline.isEmpty && !$0.link.isEmpty && $0.imageUrl != nil }
        newsArticles = validArticles
        
        for newsData in validArticles {
            let newsCard = createNewsCard(newsData: newsData)
            stackView.addArrangedSubview(newsCard)
        }
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
                return article1.publishedAt < article2.publishedAt // Fallback to string comparison
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
                return article1.publishedAt > article2.publishedAt // Fallback to string comparison
            }
            return date1 > date2
        }
        updateNewsDisplay()
    }

    private func updateNewsDisplay() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for newsData in newsArticles {
            let newsCard = createNewsCard(newsData: newsData)
            stackView.addArrangedSubview(newsCard)
        }
    }

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

        let buttonTitles = ["Last 7 days", "Last 24 hours", "Weather"]
        for (index, title) in buttonTitles.enumerated() {
            let button = UIButton()
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 5
            button.clipsToBounds = true
            
            if index == 0 {
                button.backgroundColor = .white
                button.setTitleColor(.black, for: .normal)
            } else {
                button.backgroundColor = .darkGray
            }
            
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
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
                    backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                    backButton.widthAnchor.constraint(equalToConstant: 40),
                    backButton.heightAnchor.constraint(equalToConstant: 40),

                    titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
                    titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60), // Adjusted for back button
                    titleLabel.trailingAnchor.constraint(equalTo: filterButton.leadingAnchor, constant: -20),
                    titleLabel.heightAnchor.constraint(equalToConstant: 40),
                    
                    filterButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
                    filterButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                    filterButton.widthAnchor.constraint(equalToConstant: 40),
                    filterButton.heightAnchor.constraint(equalToConstant: 40),
            
            buttonStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
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
    @objc private func dismissDetailView() {
         dismiss(animated: true, completion: nil)
     }

    private func fetchNewsData(query: String) {
        let apiKey = "30e36402849c414a9a78de022db36455"
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://newsapi.org/v2/everything?q=\(encodedQuery)&apiKey=\(apiKey)") else {
            print("Invalid URL")
            return
        }
        
        let session = URLSession.shared
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Error fetching news: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(NewsResponse.self, from: data)
                DispatchQueue.main.async {
                    self?.updateNewsData(with: response.articles)
                }
            } catch {
                print("Error parsing JSON: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw JSON: \(jsonString)")
                }
            }
        }
        task.resume()
    }
    
    @objc private func buttonPressed(sender: UIButton) {
        buttonStackView.arrangedSubviews.forEach { view in
            if let button = view as? UIButton {
                button.backgroundColor = UIColor.darkGray
                button.setTitleColor(.white, for: .normal)
            }
        }
        sender.backgroundColor = UIColor.systemGray6
        sender.setTitleColor(.black, for: .normal)

        if let buttonIndex = buttonStackView.arrangedSubviews.firstIndex(of: sender) {
            guard let location = currentLocation else {
                print("Location not available yet.")
                return
            }
            
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate]

            switch buttonIndex {
            case 0:
                if let last7Days = Calendar.current.date(byAdding: .day, value: -7, to: Date()) {
                    let fromDate = dateFormatter.string(from: last7Days)
                    fetchNewsData(query: "\(location)-road-accident OR \(location)-event OR \(location)-weather&from=\(fromDate)")
                }
            case 1:
                if let last24Hours = Calendar.current.date(byAdding: .day, value: -30, to: Date()) {
                    let fromDate = dateFormatter.string(from: last24Hours)
                    fetchNewsData(query: "\(location)-road-accident OR \(location)-event OR \(location)-weather&from=\(fromDate)")
                }
            case 2:
                if let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date()) {
                    let fromDate = dateFormatter.string(from: lastMonth)
                    fetchNewsData(query: "\(location)-weather OR \(location)-temperature OR \(location)-storm OR \(location)-rain OR \(location)-snowfall OR \(location)-heatwave OR \(location)-coldwave OR \(location)-forecast OR \(location)-climate&from=\(fromDate)")
                }
            default:
                break
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
        infoStack.axis = .horizontal
        infoStack.spacing = 8
        infoStack.alignment = .center

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
}

extension UIImageView {
    func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        if let cachedImage = ImageNewsCache.shared.getImage(for: url) {
            self.image = cachedImage
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = image
                }
                ImageNewsCache.shared.saveImage(image, for: url)
            }
        }.resume()
    }
}
