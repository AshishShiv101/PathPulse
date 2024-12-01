import Foundation
import CoreLocation
import UIKit

class WeatherService {
    static let shared = WeatherService()
    private let apiKey = "562caa4db4fe2bf5de1470e5d0f67961"
    
    private init() {}
    
    func fetchWeather(for coordinate: CLLocationCoordinate2D, completion: @escaping (WeatherData?, Error?) -> Void) {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&appid=\(apiKey)&units=metric"
        
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "WeatherService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "WeatherService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let main = json["main"] as? [String: Any],
                   let temp = main["temp"] as? Double,
                   let humidity = main["humidity"] as? Int,
                   let wind = json["wind"] as? [String: Any],
                   let windSpeed = wind["speed"] as? Double,
                   let weatherArray = json["weather"] as? [[String: Any]],
                   let weatherDescription = weatherArray.first?["description"] as? String,
                   let icon = weatherArray.first?["icon"] as? String {
                    
                    let weatherData = WeatherData(
                        temperature: temp,
                        humidity: humidity,
                        windSpeed: windSpeed,
                        description: weatherDescription,
                        icon: icon
                    )
                    
                    completion(weatherData, nil)
                }
            } catch {
                completion(nil, error)
            }
        }.resume()
    }
}
struct WeatherData {
    var temperature: Double
    var humidity: Int
    var windSpeed: Double
    var description: String
    var icon: String // The icon code used to fetch the weather icon
}

