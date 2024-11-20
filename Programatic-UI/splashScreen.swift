import UIKit

class splashScreen: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
          Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(navigateToSecondPage), userInfo: nil, repeats: false)
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#222222")
        
        let titleStack = UIStackView()
        titleStack.axis = .horizontal
        titleStack.alignment = .center
        titleStack.spacing = 8
        
        let pathLabel = UILabel()
        pathLabel.text = "Path"
        pathLabel.font = UIFont.boldSystemFont(ofSize: 65)
        pathLabel.textColor = UIColor(hex: "40CBD8")
        
        let pulseLabel = UILabel()
        pulseLabel.text = "Pulse"
        pulseLabel.font = UIFont.systemFont(ofSize: 65, weight: .light)
        pulseLabel.textColor = .white
        
        titleStack.addArrangedSubview(pathLabel)
        titleStack.addArrangedSubview(pulseLabel)
        
        let roadImageView = UIImageView(image: UIImage(systemName: "road.lanes.curved.right"))
        roadImageView.tintColor = UIColor(hex: "40CBD8")
        roadImageView.contentMode = .scaleAspectFit
        roadImageView.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView(arrangedSubviews: [titleStack, roadImageView])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = -40
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            roadImageView.widthAnchor.constraint(equalToConstant: 150),
            roadImageView.heightAnchor.constraint(equalToConstant: 150)
        ])
    }
    
    @objc private func navigateToSecondPage() {
        let secondViewController = onBoarding()
        navigationController?.pushViewController(secondViewController, animated: true)
    }
}
