import UIKit

struct News {
    let title: String
    let description: String
    let thumbnail: UIImage?
}

class NewsView: UIView {
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let thumbnailImageView = UIImageView()
    init(newsData: News) {
        super.init(frame: .zero)
        setupViews()
        configure(with: newsData)
    }  
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    private func setupViews() {
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = .lightGray
        descriptionLabel.numberOfLines = 2
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleLabel)
        addSubview(descriptionLabel)
        addSubview(thumbnailImageView)

        NSLayoutConstraint.activate([
            thumbnailImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            thumbnailImageView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 60),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 60),

            titleLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),

            descriptionLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 10),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10)
        ])
    }

    func configure(with newsData: News) {
        titleLabel.text = newsData.title
        descriptionLabel.text = newsData.description
        thumbnailImageView.image = newsData.thumbnail
    }
}
