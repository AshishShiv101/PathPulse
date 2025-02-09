import UIKit
import WebKit
import CoreLocation

// Add Image Cache
class ImageNewsCache {
    static let shared = ImageNewsCache()
    private let cache = NSCache<NSURL, UIImage>()
    
    private init() {}
    
    func saveImage(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
    
    func getImage(for url: URL) -> UIImage? {
        return cache.object(forKey: url as NSURL)
    }
}
