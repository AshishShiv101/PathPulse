import Foundation

func fetchPlaceData(for type: String, location: String, radius: Int, completion: @escaping ([GuideItem]) -> Void) {
    let baseUrl = "https://maps.googleapis.com/maps/api/place/textsearch/json"
    let query = "\(type)"
    let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    let urlString = "\(baseUrl)?query=\(encodedQuery)&location=\(location)&radius=\(radius)&key=\("AIzaSyAkRf97JQAwepJSR6coaCQBQ5WpsOWLNyE")"
    
    guard let url = URL(string: urlString) else {
        print("Invalid URL")
        completion([]) 
        return
    }
    
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            print("Error fetching places: \(error.localizedDescription)")
            completion([])
            return
        }
        
        guard let data = data else {
            print("No data received.")
            completion([])
            return
        }
        
        do {
            let decoder = JSONDecoder()
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
                    location: result.formatted_address,
                    rating: result.rating ?? 0.0,
                    imageName: imageName,
                    hours: result.opening_hours?.weekday_text?.joined(separator: ", ") ?? "N/A"
                )
            }
            completion(guideItems)
        } catch {
            print("Error decoding data: \(error.localizedDescription)")
            completion([])
        }
    }
    task.resume()
}

private func constructImageURL(from photoReference: String) -> String {
    let basePhotoUrl = "https://maps.googleapis.com/maps/api/place/photo"
    let maxWidth = 400 
    return "\(basePhotoUrl)?maxwidth=\(maxWidth)&photoreference=\(photoReference)&key=\("AIzaSyAkRf97JQAwepJSR6coaCQBQ5WpsOWLNyE")"
}
