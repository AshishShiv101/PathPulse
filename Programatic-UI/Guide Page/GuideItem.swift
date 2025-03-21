import Foundation
import MapKit

struct GuideItem {
    var title: String
    var placeId: String
    var location: String
    var rating: Double
    var userRatingsTotal: Int?
    var imageName: String!
    var hours: String
    var price: Double?
    var phoneNumber: String?
    var coordinate: CLLocationCoordinate2D?
}

struct GooglePlacesResponse: Codable {
    let results: [PlaceResult]
}
struct PlaceResult: Codable {
    let name: String
    let formatted_address: String
    let rating: Double?
    let user_ratings_total: Int? 
    let opening_hours: OpeningHours?
    let photos: [Photo]?
    let place_id: String
    let geometry: Geometry?
    
    enum CodingKeys: String, CodingKey {
        case name, formatted_address, rating, user_ratings_total, opening_hours, photos, place_id, geometry
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
