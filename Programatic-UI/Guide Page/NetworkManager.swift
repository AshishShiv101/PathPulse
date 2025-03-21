import Foundation
import CoreLocation

func fetchPlaceData(for type: String, location: String, radius: Int, completion: @escaping ([GuideItem]) -> Void) {
    let baseUrl = "https://maps.googleapis.com/maps/api/place/textsearch/json"
    let query = "\(type)"
    let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

    let encodedLocation = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    let urlString = "\(baseUrl)?query=\(encodedQuery)&location=\(encodedLocation)&radius=\(radius)&key=AIzaSyC80tpuSb7UN9YtmWhx-4qTITNdL2sgkTQ"
    

    print("Fetching URL: \(urlString)")
    
    guard let url = URL(string: urlString) else {
        print("Invalid URL: \(urlString)")
        completion([])
        return
    }
    
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            print("Error fetching places for \(type): \(error.localizedDescription)")
            completion([])
            return
        }
        
        guard let data = data else {
            print("No data received for \(type).")
            completion([])
            return
        }
        
        do {
            let decoder = JSONDecoder()
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON for \(type): \(jsonString)")
            }
            let response = try decoder.decode(GooglePlacesResponse.self, from: data)
            let guideItems = response.results.map { result -> GuideItem in
                    let imageName: String
                    if let photoReference = result.photos?.first?.photo_reference {
                        imageName = constructImageURL(from: photoReference)
                    } else {
                        imageName = ""
                    }
                    
                    var coordinate: CLLocationCoordinate2D? = nil
                    if let lat = result.geometry?.location.lat, let lng = result.geometry?.location.lng {
                        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                    }
                    
                    return GuideItem(
                        title: result.name,
                        placeId: result.place_id,
                        location: result.formatted_address,
                        rating: result.rating ?? 0.0,
                        userRatingsTotal: result.user_ratings_total,
                        imageName: imageName,
                        hours: result.opening_hours?.weekday_text?.joined(separator: ", ") ?? "N/A",
                        price: nil,
                        phoneNumber: nil,
                        coordinate: coordinate
                    )
            }
            print("Fetched \(guideItems.count) items for \(type)")
            completion(guideItems)
        } catch {
            print("Error decoding data for \(type): \(error.localizedDescription)")
            completion([])
        }
    }
    task.resume()
}
private func constructImageURL(from photoReference: String) -> String {
    let basePhotoUrl = "https://maps.googleapis.com/maps/api/place/photo"
    let maxWidth = 400
    return "\(basePhotoUrl)?maxwidth=\(maxWidth)&photoreference=\(photoReference)&key=AIzaSyC80tpuSb7UN9YtmWhx-4qTITNdL2sgkTQ"
}
