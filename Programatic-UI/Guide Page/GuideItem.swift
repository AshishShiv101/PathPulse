import Foundation

struct GuideItem {
    var title: String
    var location: String
    var rating: Double
    var imageName: String!
    var hours: String
    var price: Double?
    var phoneNumber: String?
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
}
struct OpeningHours: Codable {
    let weekday_text: [String]?
}

struct Photo: Codable {
    let photo_reference: String
    let height: Int
    let width: Int
}
