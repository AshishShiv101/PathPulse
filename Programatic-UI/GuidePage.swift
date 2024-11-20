import UIKit
class GuidePage: UIViewController, UISearchBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let locationView = UIView()

    private let carousels = ["Clinics", "Hotels", "Hospitals", "Pharmacies"]
    private var originalCarouselData: [String: [GuideItem]] = [
        "Clinics": GuideItem.DataModel.clinics,
        "Hotels": GuideItem.DataModel.hotels,
        "Hospitals": GuideItem.DataModel.hospitals,
        "Pharmacies": GuideItem.DataModel.pharmacies
    ]
    private var carouselCollectionViews: [UICollectionView] = []
    private var carouselData: [String: [GuideItem]] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#222222")
        title = "Guide"
        carouselData = originalCarouselData
        setupNavigationBar()
        setupScrollView()
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
private func reloadAllCarousels() {
        for collectionView in carouselCollectionViews {
            collectionView.reloadData()
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    private func setupCarousels() {

        var previousCarousel: UIView? = nil
            carouselCollectionViews.removeAll()
            let locationContainer = UIView()
            locationContainer.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(locationContainer)
            let locationIcon = UIImageView()
            locationIcon.image = UIImage(systemName: "location.fill")?.withRenderingMode(.alwaysTemplate)
            locationIcon.tintColor = .white
            locationIcon.translatesAutoresizingMaskIntoConstraints = false
            locationContainer.addSubview(locationIcon)

            let locationLabel = UILabel()
            locationLabel.text = "Chennai"
            locationLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
            locationLabel.textColor = .white
            locationLabel.translatesAutoresizingMaskIntoConstraints = false
            locationContainer.addSubview(locationLabel)

            // Background color for the location container
            locationContainer.backgroundColor = .black
            locationContainer.layer.cornerRadius = 10

            NSLayoutConstraint.activate([
                locationContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
                locationContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                locationContainer.heightAnchor.constraint(equalToConstant: 40),

                locationIcon.leadingAnchor.constraint(equalTo: locationContainer.leadingAnchor, constant: 10),
                locationIcon.centerYAnchor.constraint(equalTo: locationContainer.centerYAnchor),
                locationIcon.widthAnchor.constraint(equalToConstant: 25),
                locationIcon.heightAnchor.constraint(equalToConstant: 25),

                locationLabel.leadingAnchor.constraint(equalTo: locationIcon.trailingAnchor, constant: 8),
                locationLabel.centerYAnchor.constraint(equalTo: locationContainer.centerYAnchor),
                locationLabel.trailingAnchor.constraint(equalTo: locationContainer.trailingAnchor, constant: -10)
            ])

            previousCarousel = locationContainer // Set as the reference for the next component

        for (index, (title, _)) in carouselData.enumerated() {
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = UIFont.boldSystemFont(ofSize: 35)
            titleLabel.textColor = .white
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(titleLabel)
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: previousCarousel?.bottomAnchor ?? contentView.topAnchor, constant: 20),

                titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
            ])
            
            let collectionViewLayout = UICollectionViewFlowLayout()
            collectionViewLayout.scrollDirection = .horizontal
            collectionViewLayout.itemSize = CGSize(width: 170, height: 200)
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
            carouselCollectionViews.append(collectionView)
            
            NSLayoutConstraint.activate([
                collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
                collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                collectionView.heightAnchor.constraint(equalToConstant: 210)
            ])
            previousCarousel = collectionView
        }
        
        if let previousCarousel = previousCarousel {
            NSLayoutConstraint.activate([
                previousCarousel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 20)
            ])
        }
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let title = Array(carouselData.keys)[collectionView.tag]
        return carouselData[title]?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let title = Array(carouselData.keys)[collectionView.tag]
        guard let selectedItem = carouselData[title]?[indexPath.item] else { return }
        let detailedViewController = DetailedView(selectedItem: selectedItem)
        navigationController?.pushViewController(detailedViewController, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let title = Array(carouselData.keys)[collectionView.tag]
        guard let item = carouselData[title]?[indexPath.item],
              let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GuideItemCell", for: indexPath) as? GuideItemCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: item)
        return cell
    }
    
    class GuideItemCell: UICollectionViewCell {
        private let cardView = UIView()
        private let imageView = UIImageView()
        private let titleLabel = UILabel()
        private let locationLabel = UILabel()
        private let ratingLabel = UILabel()
        private let starImageView = UIImageView()
        private let hoursLabel = UILabel()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setupCardView()
            setupImageView()
            setupTitleLabel()
            setupLocationLabel()
            setupRatingLabel()
            setupStarImageView()
            setupHoursLabel()
            setupConstraints()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupCardView() {
            cardView.backgroundColor = UIColor(hex: "#333333")
            cardView.layer.cornerRadius = 15
            cardView.layer.shadowColor = UIColor.black.cgColor
            cardView.layer.shadowOpacity = 0.3
            cardView.layer.shadowOffset = CGSize(width: 0, height: 4)
            cardView.layer.shadowRadius = 6
            cardView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(cardView)
        }
        
        private func setupImageView() {
            imageView.contentMode = .scaleAspectFill
            imageView.layer.cornerRadius = 10
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
        private func setupHoursLabel() {
            hoursLabel.font = UIFont.systemFont(ofSize: 14)
            hoursLabel.textColor = .lightGray
            hoursLabel.translatesAutoresizingMaskIntoConstraints = false
            cardView.addSubview(hoursLabel)
        }
        private func setupLocationLabel() {
            locationLabel.font = UIFont.systemFont(ofSize: 14)
            locationLabel.textColor = .lightGray
            locationLabel.translatesAutoresizingMaskIntoConstraints = false
            cardView.addSubview(locationLabel)
        }
        private func setupRatingLabel() {
            ratingLabel.font = UIFont.systemFont(ofSize: 14)
            ratingLabel.textColor = .yellow
            ratingLabel.translatesAutoresizingMaskIntoConstraints = false
            cardView.addSubview(ratingLabel)
        }
        private func setupStarImageView() {
            starImageView.image = UIImage(systemName: "star.fill")?.withRenderingMode(.alwaysTemplate)
            starImageView.tintColor = .yellow
            starImageView.translatesAutoresizingMaskIntoConstraints = false
            cardView.addSubview(starImageView)
        }
        private func setupConstraints() {
            NSLayoutConstraint.activate([
                cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
                cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
                cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
                cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
                
                
                imageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
                imageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
                imageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
                imageView.heightAnchor.constraint(equalToConstant: 80),
                
                titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
                titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
                titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
                
                locationLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
                locationLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
                
                
                hoursLabel.topAnchor.constraint(equalTo: ratingLabel.bottomAnchor, constant: 5),
                hoursLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
                hoursLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
                
                ratingLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 1),
                ratingLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
                ratingLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
                
                starImageView.leadingAnchor.constraint(equalTo: ratingLabel.trailingAnchor, constant: -110),
                starImageView.topAnchor.constraint(equalTo: ratingLabel.topAnchor,constant: -1.2),
                starImageView.widthAnchor.constraint(equalToConstant: 14),
                starImageView.heightAnchor.constraint(equalToConstant: 14),
                
                ratingLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -30)
            ])
        }
        
        
        func configure(with item: GuideItem) {
            imageView.image = UIImage(named: item.imageName)
            titleLabel.text = item.title
            hoursLabel.text = item.hours
            ratingLabel.text = String(format: "%.1f", item.rating)
        }
    }
}
extension UITextField {
    func setCustomLeftPadding(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}
