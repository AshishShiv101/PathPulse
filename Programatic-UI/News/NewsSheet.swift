import UIKit
import WebKit

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

var location = "Delhi"

class NewsSheet: UIView {
    let backButton: UIButton
    let scrollView: UIScrollView
    let stackView: UIStackView
    let titleLabel: UILabel
    let buttonStackView: UIStackView
    let last24HrsButton: UIButton
    let last7DaysButton: UIButton

    override init(frame: CGRect) {
        backButton = UIButton()
        scrollView = UIScrollView()
        stackView = UIStackView()
        titleLabel = UILabel()
        buttonStackView = UIStackView()
        last24HrsButton = UIButton()
        last7DaysButton = UIButton()
        super.init(frame: frame)
        setupView()
        fetchNewsData(query: "\(location)-road-accident")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateNewsData(with newData: [NewsDataModel]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for newsData in newData {
            let newsCard = createNewsCard(newsData: newsData)
            stackView.addArrangedSubview(newsCard)
        }
    }

    private func setupView() {
        let rectangleView = UIView()
        rectangleView.backgroundColor = .systemGray
        rectangleView.layer.cornerRadius = 10
        rectangleView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(rectangleView)

        NSLayoutConstraint.activate([
            rectangleView.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
            rectangleView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            rectangleView.widthAnchor.constraint(equalToConstant: 60),
            rectangleView.heightAnchor.constraint(equalToConstant: 5)
        ])

        self.translatesAutoresizingMaskIntoConstraints = false

        backButton.translatesAutoresizingMaskIntoConstraints = false
        let backImage = UIImage(systemName: "chevron.left")
        backButton.setImage(backImage, for: .normal)
        backButton.tintColor = .white
        backButton.backgroundColor = .clear
        self.addSubview(backButton)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Latest Updates"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textAlignment = .center
        self.addSubview(titleLabel)

        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 12
        buttonStackView.alignment = .center
        buttonStackView.distribution = .fillEqually
        self.addSubview(buttonStackView)

        let buttonTitles = ["Last 7 Days", "Latest", "Weather"]
        for (index, title) in buttonTitles.enumerated() {
            let button = UIButton()
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            button.setTitleColor(.black, for: .normal)
            button.layer.cornerRadius = 5
            button.layer.masksToBounds = true
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOpacity = 0.1
            button.layer.shadowOffset = CGSize(width: 0, height: 2)
            button.layer.shadowRadius = 4

            if index == 0 {
                button.backgroundColor = UIColor.darkGray
                button.setTitleColor(.white, for: .normal)
            } else {
                button.backgroundColor = UIColor.systemGray6
            }

            button.addTarget(self, action: #selector(buttonPressed), for: .touchDown)
            buttonStackView.addArrangedSubview(button)
        }

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        self.addSubview(scrollView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        stackView.distribution = .fill
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 20),
            backButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            backButton.widthAnchor.constraint(equalToConstant: 40),

            titleLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 40),

            buttonStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            buttonStackView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            buttonStackView.heightAnchor.constraint(equalToConstant: 40),
            buttonStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),

            scrollView.topAnchor.constraint(equalTo: buttonStackView.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -20),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    private func fetchNewsData(query: String) {
        let apiKey = "30e36402849c414a9a78de022db36455"
        let urlString = "https://newsapi.org/v2/everything?q=\(query)&apiKey=\(apiKey)"

        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Error fetching news: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }

            // Print the raw JSON response for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON Response: \(jsonString)")
            }

            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(NewsResponse.self, from: data)
                DispatchQueue.main.async {
                    self?.updateNewsData(with: response.articles)
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
            }
        }.resume()
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
            switch buttonIndex {
            case 0:
                fetchNewsData(query: "\(location)-road-accident")
            case 1:
                fetchNewsData(query: "\(location)-election")
            case 2:
                fetchNewsData(query: "\(location)-air-pollution")
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
        if let imageUrl = newsData.imageUrl, let url = URL(string: imageUrl) {
            // Load image asynchronously
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        imageView.image = image
                    }
                }
            }.resume()
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

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(newsCardTapped(_:)))
        card.addGestureRecognizer(tapGesture)
        card.isUserInteractionEnabled = true
        card.tag = stackView.arrangedSubviews.count

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
        guard let card = sender.view else { return }
        if ((stackView.arrangedSubviews[card.tag] as? UIView)?.tag) != nil {
            openArticle(link: "newsData.link")
        }
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
