import UIKit
import WebKit

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
        
        for newsData in newsDataArray {
            let newsCard = createNewsCard(newsData: newsData)
            stackView.addArrangedSubview(newsCard)
        }
        
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
                updateNewsData(with: newsDataArray)
            case 1:
                updateNewsData(with: last24HoursNews)
            case 2:
                updateNewsData(with: weatherNews)
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

        let imageView = UIImageView(image: newsData.image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 6

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
        card.tag = newsDataArray.firstIndex(of: newsData) ?? 0

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
        let newsData = newsDataArray[card.tag]
        openArticle(link: newsData.link)
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
