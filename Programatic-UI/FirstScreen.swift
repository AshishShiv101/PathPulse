import UIKit

class FirstScreen: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        // Set a timer to transition to the next screen after 2 seconds (or your desired duration)
        Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(navigateToSecondPage), userInfo: nil, repeats: false)
    }

    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#222222")
        
        // Title Stack
        let titleStack = UIStackView()
        titleStack.axis = .horizontal
        titleStack.alignment = .center
        titleStack.spacing = 8
        
        // "Path" Text
        let pathLabel = UILabel()
        pathLabel.text = "Path"
        pathLabel.font = UIFont.boldSystemFont(ofSize: 65)
        pathLabel.textColor = UIColor(hex: "40CBD8")
        
        // "Pulse" Text
        let pulseLabel = UILabel()
        pulseLabel.text = "Pulse"
        pulseLabel.font = UIFont.systemFont(ofSize: 65, weight: .light)
        pulseLabel.textColor = .white
        
        // Add "Path" and "Pulse" to the title stack
        titleStack.addArrangedSubview(pathLabel)
        titleStack.addArrangedSubview(pulseLabel)
        
        // Image below title
        let roadImageView = UIImageView(image: UIImage(systemName: "road.lanes.curved.right"))
        roadImageView.tintColor = UIColor(hex: "40CBD8")
        roadImageView.contentMode = .scaleAspectFit
        roadImageView.translatesAutoresizingMaskIntoConstraints = false

        // Stack for alignment
        let stackView = UIStackView(arrangedSubviews: [titleStack, roadImageView])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = -40 // Adjust for layout
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        // Constraints
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            roadImageView.widthAnchor.constraint(equalToConstant: 150),
            roadImageView.heightAnchor.constraint(equalToConstant: 150)
        ])
    }
    
    // Navigation action
    @objc private func navigateToSecondPage() {
        let secondViewController = Second()
        navigationController?.pushViewController(secondViewController, animated: true)
    }
}
