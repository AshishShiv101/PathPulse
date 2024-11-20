import UIKit
import WebKit

class WebViewController: UIViewController {
    var urlString: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let urlString = urlString, let url = URL(string: urlString) else {
            print("Invalid URL string: \(urlString ?? "nil")") 
            return
        }

        let webView = WKWebView(frame: self.view.bounds)
        webView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(webView)

        webView.load(URLRequest(url: url))

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: self.view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }
}

