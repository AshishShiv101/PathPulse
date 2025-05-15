import UIKit
import MapKit

class GuideItemCell: UICollectionViewCell {
    private let cardView = UIView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let locationLabel = UILabel()
    private let ratingStackView = UIStackView()
    private let ratingLabel = UILabel()
    private let starImageView = UIImageView()
    private let distanceLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        
        let titleFontSize: CGFloat = isIpad ? 24 : 20
        let locationFontSize: CGFloat = isIpad ? 22 : 18
        let ratingFontSize: CGFloat = isIpad ? 20 : 16
        let distanceFontSize: CGFloat = isIpad ? 18 : 14
        
        cardView.backgroundColor = UIColor(hex: "#333333")
        cardView.layer.cornerRadius = 15
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.3
        cardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardView.layer.shadowRadius = 6
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(imageView)
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: titleFontSize)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)
        
        locationLabel.font = UIFont.systemFont(ofSize: locationFontSize)
        locationLabel.textColor = .lightGray
        locationLabel.numberOfLines = isIpad ? 2 : 1 // Allow 2 lines for iPad, 1 line for others
        locationLabel.lineBreakMode = .byTruncatingTail // Add ellipsis (...) for overflow
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(locationLabel)
        
        ratingStackView.axis = .horizontal
        ratingStackView.spacing = 4
        ratingStackView.alignment = .center
        ratingStackView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(ratingStackView)
        
        ratingLabel.font = UIFont.systemFont(ofSize: ratingFontSize)
        ratingLabel.textColor = .yellow
        ratingStackView.addArrangedSubview(ratingLabel)
        
        starImageView.image = UIImage(systemName: "star.fill")
        starImageView.tintColor = .yellow
        starImageView.translatesAutoresizingMaskIntoConstraints = false
        starImageView.widthAnchor.constraint(equalToConstant: isIpad ? 18 : 15).isActive = true
        starImageView.heightAnchor.constraint(equalToConstant: isIpad ? 18 : 15).isActive = true
        ratingStackView.addArrangedSubview(starImageView)
        
        distanceLabel.font = UIFont.boldSystemFont(ofSize: distanceFontSize)
        distanceLabel.textColor = .lightGray
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(distanceLabel)
    }
    
    private func setupConstraints() {
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        let locationToRatingSpacing: CGFloat = isIpad ? 12 : 6 // Increase gap for iPad
        let cardBottomConstant: CGFloat = isIpad ? -50 : -40 // Slightly increase card height for iPad to fit 2 lines
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: cardBottomConstant),
            
            imageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            imageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            imageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            imageView.heightAnchor.constraint(equalToConstant: 100),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            
            locationLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            locationLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            locationLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            
            ratingStackView.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: locationToRatingSpacing),
            ratingStackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            ratingStackView.trailingAnchor.constraint(lessThanOrEqualTo: cardView.trailingAnchor, constant: -10),
            
            distanceLabel.topAnchor.constraint(equalTo: ratingStackView.bottomAnchor, constant: 4),
            distanceLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            distanceLabel.trailingAnchor.constraint(lessThanOrEqualTo: cardView.trailingAnchor, constant: -10),
            distanceLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -10)
        ])
    }
    
    func configure(with item: GuideItem, userLocation: CLLocationCoordinate2D? = nil) {
        titleLabel.text = item.title
        locationLabel.text = item.location
        ratingLabel.text = "\(item.rating)"
        
        if let placeCoordinate = item.coordinate, let userCoordinate = userLocation {
            let userLocation = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
            let placeLocation = CLLocation(latitude: placeCoordinate.latitude, longitude: placeCoordinate.longitude)
            
            let distance = userLocation.distance(from: placeLocation)
            
            if distance < 1000 {
                distanceLabel.text = "📍 \(Int(distance)) m"
            } else {
                let distanceInKm = distance / 1000
                distanceLabel.text = "📍 \(String(format: "%.1f", distanceInKm)) km"
            }
        } else {
            distanceLabel.text = "Distance unavailable"
        }
        
        if let cachedImage = ImageCache.shared.image(forKey: item.imageName) {
            imageView.image = cachedImage
        } else {
            imageView.image = nil
            loadImage(from: item.imageName) { [weak self] image in
                guard let self = self, let image = image else { return }
                ImageCache.shared.setImage(image, forKey: item.imageName)
                DispatchQueue.main.async {
                    self.imageView.image = image
                }
            }
        }
    }
    
    private func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                completion(image)
            } else {
                completion(nil)
            }
        }.resume()
    }
}
