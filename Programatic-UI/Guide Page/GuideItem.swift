import Foundation

struct GuideItem {
    var title: String
    var placeId: String // Non-optional, must be provided
    var location: String
    var rating: Double
    var imageName: String! // Implicitly unwrapped optional
    var hours: String
    var price: Double?
    var phoneNumber: String? // Optional, may be nil
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
    let place_id: String // Added place_id to match GuideItem
    
    enum CodingKeys: String, CodingKey {
        case name, formatted_address, rating, opening_hours, photos, place_id
    }
}

struct OpeningHours: Codable {
    let weekday_text: [String]?
}

struct Photo: Codable {
    let photo_reference: String
    let height: Int
    let width: Int
}
