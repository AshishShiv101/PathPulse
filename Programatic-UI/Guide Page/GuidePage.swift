import UIKit

class GuidePage: UIViewController, UISearchBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var carouselData: [String: [GuideItem]] = [:]
    private var carouselCollectionViews: [UICollectionView] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#222222")
        title = "Guide"
        setupNavigationBar()
        setupCityLabel()
        setupScrollView()
        setupCarousels()
        fetchPlaceData(for: "clinic", location: "13.0827,80.2707", radius: 5000) { [weak self] guideItems in
            DispatchQueue.main.async {
                self?.carouselData["Clinics"] = guideItems
                self?.reloadAllCarousels()
            }
        }
        
        fetchPlaceData(for: "hospital", location: "13.0827,80.2707", radius: 5000) { [weak self] guideItems in
            DispatchQueue.main.async {
                self?.carouselData["Hospitals"] = guideItems
                self?.reloadAllCarousels()
            }
        }
        
        fetchPlaceData(for: "hotel", location: "13.0827,80.2707", radius: 5000) { [weak self] guideItems in
            DispatchQueue.main.async {
                self?.carouselData["Hotels"] = guideItems
                self?.reloadAllCarousels()
            }
        }

        fetchPlaceData(for: "pharmacy", location: "13.0827,80.2707", radius: 5000) { [weak self] guideItems in
            DispatchQueue.main.async {
                self?.carouselData["Pharmacies"] = guideItems
                self?.reloadAllCarousels()
            }
        }
    }
    
    private func setupCityLabel() {
        let cityLabel = UILabel()
        cityLabel.font = UIFont.boldSystemFont(ofSize: 24)
        cityLabel.textColor = .white
        cityLabel.backgroundColor = .black
        cityLabel.textAlignment = .center
        cityLabel.layer.cornerRadius = 8
        cityLabel.layer.masksToBounds = true
        cityLabel.translatesAutoresizingMaskIntoConstraints = false

        let locationAttachment = NSTextAttachment()
        locationAttachment.image = UIImage(systemName: "location.fill")?.withTintColor(.white)
        locationAttachment.bounds = CGRect(x: 0, y: -3, width: 20, height: 20)

        let attributedText = NSMutableAttributedString(attachment: locationAttachment)
        attributedText.append(NSAttributedString(string: " Chennai", attributes: [
            .foregroundColor: UIColor.white,
            .font: UIFont.boldSystemFont(ofSize: 20)
        ]))

        cityLabel.attributedText = attributedText

        contentView.addSubview(cityLabel)

        NSLayoutConstraint.activate([
            cityLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            cityLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            cityLabel.widthAnchor.constraint(equalToConstant: 150),
            cityLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    private func reloadAllCarousels() {
        for collectionView in carouselCollectionViews {
            collectionView.reloadData()
        }
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
                titleLabel.topAnchor.constraint(equalTo: previousCarousel?.bottomAnchor ?? contentView.topAnchor, constant: index == 0 ? 40 : 20),
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
