import UIKit
import FirebaseAuth // Import FirebaseAuth for authentication checks

class splashScreen: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // Start the timer to check auth and navigate after 2 seconds
        Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(checkAuthAndNavigate), userInfo: nil, repeats: false)
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
    
    @objc private func checkAuthAndNavigate() {
        if Auth.auth().currentUser != nil {
            // User is logged in, transition to the tab bar controller with MapPage
            let tabBarController = createTabBarController()
            if let window = UIApplication.shared.windows.first {
                window.rootViewController = tabBarController
                window.makeKeyAndVisible()
            }
        } else {
            // User is not logged in, navigate to onboarding
            let onboardingVC = onBoarding()
            navigationController?.pushViewController(onboardingVC, animated: true)
        }
    }
    
    private func createTabBarController() -> UITabBarController {
        // Create the MapPage
        let mapPage = MapPage() // Replace with your actual MapPage class
        mapPage.tabBarItem = UITabBarItem(title: "Map", image: UIImage(systemName: "map.fill"), tag: 0)
        
        // Example: Add other pages like GuidePage and AccountPage (customize as needed)
        let guidePage = GuidePage() // Replace with your actual GuidePage class
        guidePage.tabBarItem = UITabBarItem(title: "Guide", image: UIImage(systemName: "bookmark.fill"), tag: 1)
        let guideNavigationController = UINavigationController(rootViewController: guidePage)
        
        let accountPage = AccountPage() // Replace with your actual AccountPage class
        accountPage.tabBarItem = UITabBarItem(title: "Account", image: UIImage(systemName: "person.crop.circle"), tag: 2)
        let accountNavigationController = UINavigationController(rootViewController: accountPage)
        
        // Set up the tab bar controller
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [mapPage, guideNavigationController, accountNavigationController]
        
        // Customize tab bar appearance (optional, adjust to your design)
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(hex: "#333333")
            
            let selectedColor = UIColor(hex: "#40CBD8")
            let normalColor = UIColor.white
            
            appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
            appearance.stackedLayoutAppearance.normal.iconColor = normalColor
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
            
            tabBarController.tabBar.standardAppearance = appearance
            tabBarController.tabBar.scrollEdgeAppearance = appearance
        } else {
            tabBarController.tabBar.barTintColor = UIColor(hex: "#333333")
            tabBarController.tabBar.tintColor = UIColor(hex: "#40CBD8")
            tabBarController.tabBar.unselectedItemTintColor = .white
        }
        
        return tabBarController
    }
}
