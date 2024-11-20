import UIKit

class DetailedView: UIViewController {
    
    private let selectedItem: GuideItem
    
    init(selectedItem: GuideItem) {
        self.selectedItem = selectedItem
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    private func configureView() {
        view.backgroundColor = UIColor(hex: "#222222")
        setupLayout()
    }
    
    private func setupLayout() {
        let imageView = createImageView(with: selectedItem.imageName)
        view.addSubview(imageView)
        
        let titleLabel = createTitleLabel(with: selectedItem.title)
        view.addSubview(titleLabel)
        
        let infoContainer = createInfoContainer()
        let infoStackView = createInfoStackView()
        
        infoStackView.addArrangedSubview(createInfoLabel(title: "Address", value: selectedItem.address))
        infoStackView.addArrangedSubview(createInfoLabel(title: "Phone", value: selectedItem.phone))
        infoStackView.addArrangedSubview(createInfoLabel(title: "Hours", value: selectedItem.hours))
        infoContainer.addSubview(infoStackView)
        view.addSubview(infoContainer)
        
        let buttonStack = createButtonStack()
        buttonStack.addArrangedSubview(createActionButton(imageName: "location.fill", action: #selector(handleLocationTapped)))
        buttonStack.addArrangedSubview(createActionButton(imageName: "square.and.arrow.up", action: #selector(handleShareTapped)))
        buttonStack.addArrangedSubview(createActionButton(imageName: "phone.fill", action: #selector(handleCallTapped)))
        view.addSubview(buttonStack)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            infoContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            infoContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            infoContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            infoStackView.topAnchor.constraint(equalTo: infoContainer.topAnchor, constant: 16),
            infoStackView.leadingAnchor.constraint(equalTo: infoContainer.leadingAnchor, constant: 16),
            infoStackView.trailingAnchor.constraint(equalTo: infoContainer.trailingAnchor, constant: -16),
            infoStackView.bottomAnchor.constraint(equalTo: infoContainer.bottomAnchor, constant: -16),
            
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            buttonStack.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func createImageView(with imageName: String) -> UIImageView {
        let imageView = UIImageView()
        imageView.image = UIImage(named: imageName)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.6).cgColor]
        gradientLayer.locations = [0.5, 1.0]
        gradientLayer.frame = imageView.bounds
        imageView.layer.addSublayer(gradientLayer)
        
        return imageView
    }
    
    private func createTitleLabel(with text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.boldSystemFont(ofSize: 32)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func createInfoContainer() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#333333")
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
    private func createInfoStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }
    
    private func createInfoLabel(title: String, value: String) -> UILabel {
        let label = UILabel()
        label.text = "\(title): \(value)"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }
    
    private func createButtonStack() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }
    
    private func createActionButton(imageName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: imageName), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor(hex: "#40CBD8")
        button.layer.cornerRadius = 30
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        button.widthAnchor.constraint(equalToConstant: 60).isActive = true
        return button
    }
    
    @objc private func handleLocationTapped() {
        print("Location button tapped")
    }
    
    @objc private func handleShareTapped() {
        print("Share button tapped")
    }
    
    @objc private func handleCallTapped() {
        print("Call button tapped")
    }
}
