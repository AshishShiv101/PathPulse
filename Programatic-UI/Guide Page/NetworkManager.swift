import Foundation

func fetchPlaceData(for type: String, location: String, radius: Int, completion: @escaping ([GuideItem]) -> Void) {
    let baseUrl = "https://maps.googleapis.com/maps/api/place/textsearch/json"
    let query = "\(type)"
    let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    // Location ko bhi encode karo taaki special characters (jaise comma) se URL na toote
    let encodedLocation = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    let urlString = "\(baseUrl)?query=\(encodedQuery)&location=\(encodedLocation)&radius=\(radius)&key=AIzaSyBLC650TGPXxPxS0RPEMe9zs5yFocnO0qk"
    
    // URL print karo taaki check kar sako
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
            // Raw JSON print karo taaki response dekha ja sake
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
                
                return GuideItem(
                    title: result.name,
                    placeId: result.place_id,
                    location: result.formatted_address,
                    rating: result.rating ?? 0.0,
                    imageName: imageName,
                    hours: result.opening_hours?.weekday_text?.joined(separator: ", ") ?? "N/A"
                )
            }
            // Kitne items fetch hue, yeh print karo
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
    return "\(basePhotoUrl)?maxwidth=\(maxWidth)&photoreference=\(photoReference)&key=AIzaSyBLC650TGPXxPxS0RPEMe9zs5yFocnO0qk"
}
