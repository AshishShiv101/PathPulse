import UIKit

class GuidePage: UIViewController, UISearchBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Get the key (title) for the collection view using its tag
        let title = Array(carouselData.keys)[collectionView.tag]
        
        // Safely unwrap the item for the given section and indexPath
        guard let item = carouselData[title]?[indexPath.item],
              let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GuideItemCell", for: indexPath) as? GuideItemCell else {
            // Return an empty cell if something goes wrong
            return UICollectionViewCell()
        }

        cell.configure(with: item)
        
        return cell
    }
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let locationView = UIView()
    private let searchTextField = UITextField()
    private let carousels = ["Clinics", "Hotels", "Hospitals", "Pharmacies"]
    private var carouselData: [String: [GuideItem]] = [
        "Clinics": DataModel.clinics,
        "Hotels": DataModel.hotels,
        "Hospitals": DataModel.hospitals,
        "Pharmacies": DataModel.pharmacies
    ]
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#222222")
        title = "Guide"
        setupNavigationBar()
        setupScrollView()
        setupSearchBar()
        setupCarousels()
    }

    private func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(hex: "#222222")
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
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

    private func setupSearchBar() {
        let searchContainer = UIStackView()
        searchContainer.axis = .horizontal
        searchContainer.spacing = 8
        searchContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(searchContainer)
        
        locationView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        locationView.layer.cornerRadius = 10
        locationView.translatesAutoresizingMaskIntoConstraints = false
        let locationLabel = UILabel()
        locationLabel.text = "Chennai"
        locationLabel.textColor = .white
        let locationImageView = UIImageView(image: UIImage(systemName: "location.fill"))
        locationImageView.tintColor = .white
        locationView.addSubview(locationImageView)
        locationView.addSubview(locationLabel)
        
        locationImageView.translatesAutoresizingMaskIntoConstraints = false
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            locationImageView.leadingAnchor.constraint(equalTo: locationView.leadingAnchor, constant: 10),
            locationImageView.centerYAnchor.constraint(equalTo: locationView.centerYAnchor),
            locationLabel.leadingAnchor.constraint(equalTo: locationImageView.trailingAnchor, constant: 10),
            locationLabel.centerYAnchor.constraint(equalTo: locationView.centerYAnchor),
            locationLabel.trailingAnchor.constraint(equalTo: locationView.trailingAnchor, constant: -10),
            locationView.heightAnchor.constraint(equalToConstant: 50),
            locationView.widthAnchor.constraint(equalToConstant: 120)
        ])
        
        searchTextField.placeholder = "Search"
        searchTextField.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        searchTextField.layer.cornerRadius = 10
        searchTextField.setCustomLeftPadding(10)
        searchTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        searchContainer.addArrangedSubview(locationView)
        searchContainer.addArrangedSubview(searchTextField)
        
        NSLayoutConstraint.activate([
            searchContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            searchContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            searchContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    private func setupCarousels() {
        var previousCarousel: UIView? = nil
        for (index, (title, _)) in carouselData.enumerated() {
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
            titleLabel.textColor = .white
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(titleLabel)
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: previousCarousel?.bottomAnchor ?? searchTextField.bottomAnchor, constant: 20),
                titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
            ])
            let collectionViewLayout = UICollectionViewFlowLayout()
            collectionViewLayout.scrollDirection = .horizontal
            collectionViewLayout.itemSize = CGSize(width: 170, height: 140)
            collectionViewLayout.minimumLineSpacing = 10
            let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
            collectionView.tag = index
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.register(GuideItemCell.self, forCellWithReuseIdentifier: "GuideItemCell")
            collectionView.backgroundColor = .clear
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(collectionView)
            collectionView.showsHorizontalScrollIndicator = false

            NSLayoutConstraint.activate([
                collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
                collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                collectionView.heightAnchor.constraint(equalToConstant: 120)
            ])
            previousCarousel = collectionView
        }
        if let previousCarousel = previousCarousel {
            NSLayoutConstraint.activate([
                previousCarousel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 20)
            ])
        }
    }

    // MARK: - CollectionView DataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Get the correct key for the collection view using the tag, then fetch data for that section
        let title = Array(carouselData.keys)[collectionView.tag]
        return carouselData[title]?.count ?? 0
    }
    
    // MARK: - CollectionView Delegate
    // UICollectionView Delegate method for item selection
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Get the title of the selected carousel
        let title = Array(carouselData.keys)[collectionView.tag]
        
        // Get the selected item
        guard let selectedItem = carouselData[title]?[indexPath.item] else { return }
        
        // Push to DetailedViewController and pass selectedItem
        let detailedViewController = DetailedView(selectedItem: selectedItem)
        navigationController?.pushViewController(detailedViewController, animated: true)
    }


}

class GuideItemCell: UICollectionViewCell {
    private let cardView = UIView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let locationLabel = UILabel()
    private let ratingLabel = UILabel()  // Keep this if you want to display the rating text

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupCardView()
        setupImageView()
        setupTitleLabel()
        setupLocationLabel()
        setupRatingComponents() // We will keep this but remove the star icon setup
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCardView() {
        cardView.backgroundColor = UIColor(hex: "#333333") // Dark background for the card
        cardView.layer.cornerRadius = 12
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.2
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 4
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
    }
    
    private func setupImageView() {
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 8
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(imageView)
    }
    
    private func setupTitleLabel() {
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)
    }
    
    private func setupLocationLabel() {
        locationLabel.font = UIFont.systemFont(ofSize: 14)
        locationLabel.textColor = .lightGray
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(locationLabel)
    }
    
    private func setupRatingComponents() {
        // We will skip the starImageView setup to remove the star icon
        ratingLabel.font = UIFont.systemFont(ofSize: 14)
        ratingLabel.textColor = .white
        ratingLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(ratingLabel)
    }

    private func setupConstraints() {
        // Card view constraints
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        
        // Image view constraints
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 8),
            imageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 8),
            imageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8),
            imageView.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        // Title label constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8)
        ])
        
        // Location label constraints
        NSLayoutConstraint.activate([
            locationLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            locationLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 8),
            locationLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8)
        ])
        
        // Rating label constraints (without the star icon)
        NSLayoutConstraint.activate([
            ratingLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 4),
            ratingLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 8),
            ratingLabel.trailingAnchor.constraint(lessThanOrEqualTo: cardView.trailingAnchor, constant: -8),
            ratingLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with item: GuideItem) {
        imageView.image = UIImage(named: item.imageName)
        titleLabel.text = item.title
        
 
    }

}




// Add padding to UITextField
extension UITextField {
    func setCustomLeftPadding(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}
