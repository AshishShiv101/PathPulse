import Foundation
import CoreLocation

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
                print("Fetch weather error: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                print("Fetch weather: No data received")
                completion(nil, NSError(domain: "WeatherService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                      let main = json["main"] as? [String: Any],
                      let temp = main["temp"] as? Double,
                      let humidity = main["humidity"] as? Int,
                      let pressure = main["pressure"] as? Int,
                      let wind = json["wind"] as? [String: Any],
                      let windSpeed = wind["speed"] as? Double,
                      let weatherArray = json["weather"] as? [[String: Any]],
                      let weather = weatherArray.first,
                      let weatherDescription = weather["description"] as? String,
                      let icon = weather["icon"] as? String,
                      let visibility = json["visibility"] as? Int,
                      let coord = json["coord"] as? [String: Any],
                      let latitude = coord["lat"] as? Double,
                      let longitude = coord["lon"] as? Double
                else {
                    print("Fetch weather: Invalid JSON structure")
                    completion(nil, NSError(domain: "WeatherService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON structure"]))
                    return
                }
                
                let weatherData = WeatherData(
                    temperature: temp,
                    humidity: humidity,
                    windSpeed: windSpeed,
                    description: weatherDescription,
                    icon: icon,
                    date: Date(),
                    pressure: pressure,
                    visibility: visibility,
                    uvIndex: nil,
                    latitude: latitude,
                    longitude: longitude
                )
                completion(weatherData, nil)
            } catch {
                print("Fetch weather JSON error: \(error.localizedDescription)")
                completion(nil, error)
            }
        }.resume()
    }
    
    // MARK: - 24-Hour Hourly Forecast
    func fetchHourlyForecast(for coordinate: CLLocationCoordinate2D, completion: @escaping ([WeatherData]?, Error?) -> Void) {
        let urlString = "https://api.openweathermap.org/data/2.5/forecast?lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&appid=\(apiKey)&units=metric"
        
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "WeatherService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Fetch hourly forecast error: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                print("Fetch hourly forecast: No data received")
                completion(nil, NSError(domain: "WeatherService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                      let hourlyList = json["list"] as? [[String: Any]] else {
                    print("Fetch hourly forecast: Invalid JSON structure")
                    completion(nil, NSError(domain: "WeatherService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON structure"]))
                    return
                }
                
                let hourlyWeatherData = hourlyList.prefix(8).compactMap { hour -> WeatherData? in
                    guard let main = hour["main"] as? [String: Any],
                          let temp = main["temp"] as? Double,
                          let humidity = main["humidity"] as? Int,
                          let pressure = main["pressure"] as? Int,
                          let wind = hour["wind"] as? [String: Any],
                          let windSpeed = wind["speed"] as? Double,
                          let weatherArray = hour["weather"] as? [[String: Any]],
                          let weather = weatherArray.first,
                          let weatherDescription = weather["description"] as? String,
                          let icon = weather["icon"] as? String,
                          let dt = hour["dt"] as? Double else {
                        return nil
                    }
                    
                    let visibility = hour["visibility"] as? Int ?? 10000
                    return WeatherData(
                        temperature: temp,
                        humidity: humidity,
                        windSpeed: windSpeed,
                        description: weatherDescription,
                        icon: icon,
                        date: Date(timeIntervalSince1970: dt),
                        pressure: pressure,
                        visibility: visibility,
                        uvIndex: nil,
                        latitude: coordinate.latitude,  // Use input coordinate
                        longitude: coordinate.longitude // Use input coordinate
                    )
                }
                print("Fetched \(hourlyWeatherData.count) hourly forecast items")
                completion(hourlyWeatherData, nil)
            } catch {
                print("Fetch hourly forecast JSON error: \(error.localizedDescription)")
                completion(nil, error)
            }
        }.resume()
    }
    
    // MARK: - 6-Day Weekly Forecast
    func fetchWeeklyForecast(for coordinate: CLLocationCoordinate2D, completion: @escaping ([DailyWeatherData]?, Error?) -> Void) {
        let urlString = "https://api.openweathermap.org/data/2.5/forecast?lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&appid=\(apiKey)&units=metric"
        
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "WeatherService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Fetch weekly forecast error: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                print("Fetch weekly forecast: No data received")
                completion(nil, NSError(domain: "WeatherService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                      let list = json["list"] as? [[String: Any]] else {
                    print("Fetch weekly forecast: Invalid JSON structure")
                    completion(nil, NSError(domain: "WeatherService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON structure"]))
                    return
                }
                
                var dailyWeatherData: [DailyWeatherData] = []
                var currentDay: Date?
                
                for day in list {
                    guard let dt = day["dt"] as? Double,
                          let main = day["main"] as? [String: Any],
                          let temp = main["temp"] as? Double,
                          let humidity = main["humidity"] as? Int,
                          let pressure = main["pressure"] as? Int,
                          let wind = day["wind"] as? [String: Any],
                          let windSpeed = wind["speed"] as? Double,
                          let weatherArray = day["weather"] as? [[String: Any]],
                          let weather = weatherArray.first,
                          let weatherDescription = weather["description"] as? String,
                          let icon = weather["icon"] as? String else {
                        continue
                    }
                    
                    let date = Date(timeIntervalSince1970: dt)
                    let calendar = Calendar.current
                    let dayComponent = calendar.startOfDay(for: date)
                    let visibility = day["visibility"] as? Int ?? 10000
                    
                    if currentDay != dayComponent {
                        currentDay = dayComponent
                        let dailyData = DailyWeatherData(
                            date: date,
                            temperature: temp,
                            humidity: humidity,
                            windSpeed: windSpeed,
                            description: weatherDescription,
                            icon: icon,
                            pressure: pressure,
                            visibility: visibility,
                            uvIndex: nil
                        )
                        dailyWeatherData.append(dailyData)
                    }
                    
                    if dailyWeatherData.count >= 6 {
                        break
                    }
                }
                print("Fetched \(dailyWeatherData.count) daily forecast items")
                completion(dailyWeatherData, nil)
            } catch {
                print("Fetch weekly forecast JSON error: \(error.localizedDescription)")
                completion(nil, error)
            }
        }.resume()
    }
    
    // MARK: - Air Quality
    func fetchAirQuality(for coordinate: CLLocationCoordinate2D, completion: @escaping (AirQuality?, Error?) -> Void) {
        let urlString = "http://api.openweathermap.org/data/2.5/air_pollution?lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&appid=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "WeatherService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Fetch air quality error: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                print("Fetch air quality: No data received")
                completion(nil, NSError(domain: "WeatherService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                      let list = json["list"] as? [[String: Any]],
                      let first = list.first,
                      let main = first["main"] as? [String: Any],
                      let aqi = main["aqi"] as? Int,
                      let components = first["components"] as? [String: Any],
                      let pm25 = components["pm2_5"] as? Double,
                      let pm10 = components["pm10"] as? Double else {
                    print("Fetch air quality: Invalid JSON structure")
                    completion(nil, NSError(domain: "WeatherService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON structure"]))
                    return
                }
                
                let airQuality = AirQuality(
                    aqi: aqi,
                    pm25: pm25,
                    pm10: pm10
                )
                completion(airQuality, nil)
            } catch {
                print("Fetch air quality JSON error: \(error.localizedDescription)")
                completion(nil, error)
            }
        }.resume()
    }
}

// MARK: - Data Structures
struct WeatherData {
    var temperature: Double
    var humidity: Int
    var windSpeed: Double
    var description: String
    var icon: String
    var date: Date
    var pressure: Int
    var visibility: Int
    var uvIndex: Double?
    var latitude: Double
    var longitude: Double
}

struct DailyWeatherData {
    var date: Date
    var temperature: Double
    var humidity: Int
    var windSpeed: Double
    var description: String
    var icon: String
    var pressure: Int
    var visibility: Int
    var uvIndex: Double?
}

struct AirQuality {
    let aqi: Int 
    let pm25: Double
    let pm10: Double
}
