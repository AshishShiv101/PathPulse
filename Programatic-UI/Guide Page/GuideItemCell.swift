import UIKit

class GuideItemCell: UICollectionViewCell {
    private let cardView = UIView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let locationLabel = UILabel()
    private let ratingStackView = UIStackView()
    private let ratingLabel = UILabel()
    private let starImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
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
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)
        
        locationLabel.font = UIFont.systemFont(ofSize: 18)
        locationLabel.textColor = .lightGray
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(locationLabel)
        
        ratingStackView.axis = .horizontal
        ratingStackView.spacing = 4
        ratingStackView.alignment = .center
        ratingStackView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(ratingStackView)
        
        ratingLabel.font = UIFont.systemFont(ofSize: 16)
        ratingLabel.textColor = .yellow
        ratingStackView.addArrangedSubview(ratingLabel)
        
        starImageView.image = UIImage(systemName: "star.fill")
        starImageView.tintColor = .yellow
        starImageView.translatesAutoresizingMaskIntoConstraints = false
        starImageView.widthAnchor.constraint(equalToConstant: 15).isActive = true
        starImageView.heightAnchor.constraint(equalToConstant: 15).isActive = true
        ratingStackView.addArrangedSubview(starImageView)
    }
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40), // Increased bottom padding
            
            imageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            imageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            imageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            imageView.heightAnchor.constraint(equalToConstant: 100), // Reduced height to allow space for ratingStackView
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            
            locationLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            locationLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            locationLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            
            ratingStackView.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 6),
            ratingStackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            ratingStackView.trailingAnchor.constraint(lessThanOrEqualTo: cardView.trailingAnchor, constant: -10),
            ratingStackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -10) // Ensures it stays inside the card
        ])
    }
  func configure(with item: GuideItem) {
        titleLabel.text = item.title
        locationLabel.text = item.location
        ratingLabel.text = "\(item.rating)"
        
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
