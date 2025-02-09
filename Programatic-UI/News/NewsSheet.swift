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

    enum CodingKeys: String, CodingKey {
        case headline = "title"
        case link = "url"
        case imageUrl = "urlToImage"
    }
}
class NewsSheet: UIView, CLLocationManagerDelegate {
    let scrollView: UIScrollView
    let stackView: UIStackView
    let titleLabel: UILabel
    let buttonStackView: UIStackView
    let last24HrsButton: UIButton
    let last7DaysButton: UIButton
    private let locationManager = CLLocationManager()
    private var currentLocation: String? // Changed to optional

    override init(frame: CGRect) {
        scrollView = UIScrollView()
        stackView = UIStackView()
        titleLabel = UILabel()
        buttonStackView = UIStackView()
        last24HrsButton = UIButton()
        last7DaysButton = UIButton()
        super.init(frame: frame)
        setupLocationManager()
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
                guard let self = self, let placemark = placemarks?.first, let city = placemark.locality else { return }
                
                self.currentLocation = city
                print("Current location: \(city)")
                
                DispatchQueue.main.async {
                    self.fetchNewsData(query: "\(city)-road-accident")
                }
            }
            locationManager.stopUpdatingLocation()
        }
    private func updateNewsData(with newData: [NewsDataModel]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let validArticles = newData.filter { !$0.headline.isEmpty && !$0.link.isEmpty && $0.imageUrl != nil }
        
        for newsData in validArticles {
            let newsCard = createNewsCard(newsData: newsData)
            stackView.addArrangedSubview(newsCard)
        }
    }



    private func setupView() {
            // Title Setup
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.text = "Latest Updates"
            titleLabel.textColor = .white
            titleLabel.font = .boldSystemFont(ofSize: 20)
            titleLabel.textAlignment = .center
            addSubview(titleLabel)
            
            // Button Stack Setup
            buttonStackView.translatesAutoresizingMaskIntoConstraints = false
            buttonStackView.axis = .horizontal
            buttonStackView.spacing = 12
            buttonStackView.alignment = .center
            buttonStackView.distribution = .fillEqually
            addSubview(buttonStackView)
            
            // Create Buttons
            let buttonTitles = ["Road", "Rail", "Air"]
            for (index, title) in buttonTitles.enumerated() {
                let button = UIButton()
                button.translatesAutoresizingMaskIntoConstraints = false
                button.setTitle(title, for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
                button.setTitleColor(.black, for: .normal)
                button.layer.cornerRadius = 5
                button.clipsToBounds = true
                
                if index == 0 {
                    button.backgroundColor = .darkGray
                    button.setTitleColor(.white, for: .normal)
                } else {
                    button.backgroundColor = .systemGray6
                }
                
                button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
                buttonStackView.addArrangedSubview(button)
            }
            
            // ScrollView Setup
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.showsVerticalScrollIndicator = false
            scrollView.backgroundColor = .clear
            addSubview(scrollView)
            
            // Stack View Setup
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .vertical
            stackView.spacing = 20
            stackView.alignment = .fill
            stackView.distribution = .fill
            scrollView.addSubview(stackView)
            
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
                titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
                titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
                titleLabel.heightAnchor.constraint(equalToConstant: 40),
                
                buttonStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
                buttonStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
                buttonStackView.heightAnchor.constraint(equalToConstant: 40),
                buttonStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
                buttonStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
                
                scrollView.topAnchor.constraint(equalTo: buttonStackView.bottomAnchor, constant: 20),
                scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
                scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
                scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
                
                stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
            ])
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
                   button.backgroundColor = UIColor.systemGray6
                   button.setTitleColor(.black, for: .normal)
               }
           }
           sender.backgroundColor = UIColor.darkGray
           sender.setTitleColor(.white, for: .normal)

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
                   if let last24Hours = Calendar.current.date(byAdding: .hour, value: -24, to: Date()) {
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
            imageView.loadImage(from: imageUrl) // Lazy load image using URL
        }

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = newsData.headline
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingTail

        let arrowImageView = UIImageView()
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        arrowImageView.image = UIImage(systemName: "chevron.right")
        arrowImageView.tintColor = .white
        arrowImageView.contentMode = .scaleAspectFit

        let horizontalStackView = UIStackView(arrangedSubviews: [imageView, titleLabel, arrowImageView])
        horizontalStackView.translatesAutoresizingMaskIntoConstraints = false
        horizontalStackView.axis = .horizontal
        horizontalStackView.spacing = 12
        horizontalStackView.alignment = .center
        horizontalStackView.distribution = .fill

        card.addSubview(horizontalStackView)
        
        // Set the article's link to the card's accessibilityValue
        card.accessibilityValue = newsData.link

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(newsCardTapped(_:)))
        card.addGestureRecognizer(tapGesture)
        card.isUserInteractionEnabled = true

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60),
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
        guard let card = sender.view, let link = card.accessibilityValue else {
            print("No link associated with this card.")
            return
        }
        openArticle(link: link)
    }

    private func openArticle(link: String) {
        guard let url = URL(string: link) else {
            print("Invalid URL string: \(link)")
            return
        }

        print("Opening URL: \(url.absoluteString)")

        let webViewController = WebViewController()
        webViewController.urlString = link

        if let viewController = self.viewController(), let navigationController = viewController.navigationController {
            navigationController.pushViewController(webViewController, animated: true)
        } else {
            self.viewController()?.present(webViewController, animated: true, completion: nil)
        }
    }
}
extension UIView {
    func viewController() -> UIViewController? {
        var nextResponder: UIResponder? = self
        while nextResponder != nil {
            nextResponder = nextResponder?.next
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}
extension UIImageView {
    func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        // Check if the image is already cached
        if let cachedImage = ImageNewsCache.shared.getImage(for: url) {
            self.image = cachedImage
            return
        }
        
        // Fetch and cache the image
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
