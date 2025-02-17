import UIKit

class BottomSheetViewController: UIViewController {
    
    var cityName: String?
    var weatherInfo: String?
    var cityImageURL: String?
    var cityDescription: String?
    var location: String?
    
    private var guideItems: [GuideItem] = []

    private let cityImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textAlignment = .center
        return label
    }()
    
    private let weatherLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private let placesTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PlaceCell")
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupLayout()
        updateUI()
        
        placesTableView.dataSource = self
        placesTableView.delegate = self  // Add delegate for interactivity
        
        fetchNearbyPlaces()
    }
    
    private func setupLayout() {
        view.addSubview(cityImageView)
        view.addSubview(titleLabel)
        view.addSubview(weatherLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(placesTableView)
        
        cityImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        weatherLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        placesTableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cityImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            cityImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cityImageView.widthAnchor.constraint(equalToConstant: 200),
            cityImageView.heightAnchor.constraint(equalToConstant: 150),
            
            titleLabel.topAnchor.constraint(equalTo: cityImageView.bottomAnchor, constant: 10),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            weatherLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            weatherLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            descriptionLabel.topAnchor.constraint(equalTo: weatherLabel.bottomAnchor, constant: 10),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            placesTableView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 10),
            placesTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            placesTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            placesTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func updateUI() {
        titleLabel.text = cityName ?? "Unknown City"
        weatherLabel.text = weatherInfo ?? "No weather data available"
        descriptionLabel.text = cityDescription ?? "No description available"

        if let imageURL = cityImageURL, let url = URL(string: imageURL) {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        self.cityImageView.image = UIImage(data: data)
                    }
                }
            }
        }
    }
    
    private func fetchNearbyPlaces() {
        guard let location = location else { return }
        
        fetchPlaceData(for: "tourist attractions", location: location, radius: 5000) { [weak self] places in
            DispatchQueue.main.async {
                self?.guideItems = places
                self?.placesTableView.reloadData()
            }
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension BottomSheetViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return guideItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceCell", for: indexPath)
        let place = guideItems[indexPath.row]

        cell.textLabel?.text = "\(place.title) - ⭐ \(place.rating ?? 0.0)"
        cell.textLabel?.numberOfLines = 2

        // Placeholder image
        cell.imageView?.image = UIImage(named: "placeholder")

        if let imageURL = place.imageName, let url = URL(string: imageURL) {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        cell.imageView?.image = image
                        cell.setNeedsLayout() // Force the cell to update layout
                    }
                }
            }
        }

        return cell
    }

    
    // Handle selection (optional)
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedPlace = guideItems[indexPath.row]
        print("Selected Place: \(selectedPlace.title)")
    }
}
