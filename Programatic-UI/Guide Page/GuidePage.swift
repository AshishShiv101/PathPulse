import UIKit
import CoreLocation

class GuidePage: UIViewController, UISearchBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource, CLLocationManagerDelegate {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var carouselData: [String: [GuideItem]] = [:]
    private var carouselCollectionViews: [UICollectionView] = []
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocationCoordinate2D?
    private var cityHeader: UIView!
    private var cityLabel: UILabel!
    private var filterButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#222222")
        setupLocationManager()
        setupCityHeader()
        setupScrollView()
        setupCarousels()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1000
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    private func setupCityHeader() {
        cityHeader = UIView()
        cityHeader.backgroundColor = UIColor(hex: "#333333") // Updated background color
        cityHeader.layer.cornerRadius = 12
        cityHeader.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cityHeader)
        
        // City Label
        cityLabel = UILabel()
        cityLabel.font = UIFont.boldSystemFont(ofSize: 24)
        cityLabel.textColor = .white
        cityLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Filter Button
        filterButton = UIButton(type: .system)
        filterButton.setImage(UIImage(systemName: "line.horizontal.3.decrease.circle"), for: .normal)
        filterButton.tintColor = .white
        filterButton.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        filterButton.layer.cornerRadius = 8
        filterButton.clipsToBounds = true
        filterButton.translatesAutoresizingMaskIntoConstraints = false
        filterButton.addTarget(self, action: #selector(showFilterOptions), for: .touchUpInside)
        
        // Add subviews to cityHeader
        cityHeader.addSubview(cityLabel)
        cityHeader.addSubview(filterButton)
        
        NSLayoutConstraint.activate([
            // Reduced top gap by using negative constant
            cityHeader.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -10),
            cityHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cityHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            cityHeader.heightAnchor.constraint(equalToConstant: 50),
            
            cityLabel.centerYAnchor.constraint(equalTo: cityHeader.centerYAnchor),
            cityLabel.leadingAnchor.constraint(equalTo: cityHeader.leadingAnchor, constant: 10),
            
            filterButton.centerYAnchor.constraint(equalTo: cityHeader.centerYAnchor),
            filterButton.trailingAnchor.constraint(equalTo: cityHeader.trailingAnchor, constant: -10),
            filterButton.widthAnchor.constraint(equalToConstant: 30),
            filterButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        // Initial location text
        let locationAttachment = NSTextAttachment()
        locationAttachment.image = UIImage(systemName: "location.fill")?.withTintColor(.white)
        locationAttachment.bounds = CGRect(x: 0, y: -3, width: 20, height: 20)
        let attributedText = NSMutableAttributedString(attachment: locationAttachment)
        attributedText.append(NSAttributedString(string: " Locating...", attributes: [
            .foregroundColor: UIColor.white,
            .font: UIFont.boldSystemFont(ofSize: 20)
        ]))
        cityLabel.attributedText = attributedText
    }
    
    private func reloadAllCarousels() {
        for collectionView in carouselCollectionViews {
            collectionView.reloadData()
        }
    }
    @objc private func showFilterOptions() {
        let alert = UIAlertController(title: "Filter Options", message: "Sort by:", preferredStyle: .actionSheet)
        
        let sortByRatingAction = UIAlertAction(title: "Rating (High to Low)", style: .default) { _ in
            self.filterByRating()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(sortByRatingAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    private func filterByRating() {
        carouselData = carouselData.mapValues { items in
            items.sorted { $0.rating > $1.rating }
        }
        reloadAllCarousels()
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: cityHeader.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupCarousels() {
        var previousCarousel: UIView? = nil
        carouselCollectionViews.removeAll()
        let carouselTitles = ["Clinics", "Hospitals", "Hotels", "Pharmacies"]
        
        for (index, title) in carouselTitles.enumerated() {
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = UIFont.boldSystemFont(ofSize: 30)
            titleLabel.textColor = .white
            titleLabel.textAlignment = .left
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(titleLabel)
            
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: previousCarousel?.bottomAnchor ?? contentView.topAnchor, constant: index == 0 ? 20 : 20),
                titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16)
            ])
            
            let collectionViewLayout = UICollectionViewFlowLayout()
            collectionViewLayout.scrollDirection = .horizontal
            collectionViewLayout.itemSize = CGSize(width: 200, height: 240)
            collectionViewLayout.minimumLineSpacing = 10
            
            let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
            collectionView.tag = index
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.register(GuideItemCell.self, forCellWithReuseIdentifier: "GuideItemCell")
            collectionView.backgroundColor = .clear
            collectionView.layer.cornerRadius = 12
            collectionView.showsHorizontalScrollIndicator = false
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(collectionView)
            carouselCollectionViews.append(collectionView)
            
            NSLayoutConstraint.activate([
                collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
                collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                collectionView.heightAnchor.constraint(equalToConstant: 260)
            ])
            
            previousCarousel = collectionView
        }
        
        if let previousCarousel = previousCarousel {
            NSLayoutConstraint.activate([
                previousCarousel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
            ])
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let newLocation = location.coordinate
        
        if currentLocation == nil || distance(from: currentLocation!, to: newLocation) >= 1000 {
            currentLocation = newLocation
            
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
                guard let self = self,
                      let placemark = placemarks?.first,
                      let city = placemark.locality else { return }
                
                DispatchQueue.main.async {
                    self.updateCityLabel(with: city)
                    self.fetchNearbyPlaces()
                }
            }
        }
    }
    
    private func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Error: \(error.localizedDescription)")
    }
    
    private func updateCityLabel(with city: String) {
        let locationAttachment = NSTextAttachment()
        locationAttachment.image = UIImage(systemName: "location.fill")?.withTintColor(.white)
        locationAttachment.bounds = CGRect(x: 0, y: -3, width: 20, height: 20)
        
        let attributedText = NSMutableAttributedString(attachment: locationAttachment)
        attributedText.append(NSAttributedString(string: " \(city)", attributes: [
            .foregroundColor: UIColor.white,
            .font: UIFont.boldSystemFont(ofSize: 20)
        ]))
        
        cityLabel.attributedText = attributedText
    }
    
    private func fetchNearbyPlaces() {
        guard let location = currentLocation else { return }
        let locationString = "\(location.latitude),\(location.longitude)"
        
        let categories = ["clinic", "hospital", "hotel", "pharmacy"]
        let titles = ["Clinics", "Hospitals", "Hotels", "Pharmacies"]
        
        for (category, title) in zip(categories, titles) {
            fetchPlaceData(for: category, location: locationString, radius: 5000) { [weak self] guideItems in
                DispatchQueue.main.async {
                    self?.carouselData[title] = guideItems
                    self?.reloadAllCarousels()
                }
            }
        }
    }
    
    // MARK: - CollectionView Delegate & DataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let title = ["Clinics", "Hospitals", "Hotels", "Pharmacies"][collectionView.tag]
        return carouselData[title]?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let title = ["Clinics", "Hospitals", "Hotels", "Pharmacies"][collectionView.tag]
        guard let item = carouselData[title]?[indexPath.item],
              let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GuideItemCell", for: indexPath) as? GuideItemCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: item)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let title = ["Clinics", "Hospitals", "Hotels", "Pharmacies"][collectionView.tag]
        guard let selectedItem = carouselData[title]?[indexPath.item] else { return }
        let detailedViewController = DetailedView(selectedItem: selectedItem)
        navigationController?.pushViewController(detailedViewController, animated: true)
    }
}
