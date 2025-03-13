import Foundation
import MapKit // Add MapKit import

struct GuideItem {
    var title: String
    var placeId: String // Non-optional, must be provided
    var location: String
    var rating: Double
    var imageName: String! // Implicitly unwrapped optional
    var hours: String
    var price: Double?
    var phoneNumber: String? // Optional, may be nil
    var coordinate: CLLocationCoordinate2D? // Add coordinate property
}

struct GooglePlacesResponse: Codable {
    let results: [PlaceResult]
}
struct PlaceResult: Codable {
    let name: String
    let formatted_address: String
    let rating: Double?
    let opening_hours: OpeningHours?
    let photos: [Photo]?
    let place_id: String
    let geometry: Geometry?
    
    enum CodingKeys: String, CodingKey {
        case name, formatted_address, rating, opening_hours, photos, place_id, geometry
    }
}
struct Geometry: Codable {
    let location: Location
}

struct Location: Codable {
    let lat: Double
    let lng: Double
}

struct OpeningHours: Codable {
    let weekday_text: [String]?
}

struct Photo: Codable {
    let photo_reference: String
    let height: Int
    let width: Int
}
