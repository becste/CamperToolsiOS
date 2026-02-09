import Foundation
import Combine

struct WeatherData: Codable {
    let current_weather: CurrentWeather
    let hourly: HourlyUnits
    let daily: DailyUnits
}

struct CurrentWeather: Codable {
    let temperature: Double
    let windspeed: Double
    let winddirection: Double
    let weathercode: Int
}

struct HourlyUnits: Codable {
    let time: [String]
    let temperature_2m: [Double]
    let precipitation: [Double]
    let weathercode: [Int]
    let winddirection_10m: [Double]
    let cloudcover: [Double]?
    let sunshine_duration: [Double]?
    let is_day: [Int]?
}

struct DailyUnits: Codable {
    let time: [String]
    let sunrise: [String]
    let sunset: [String]
    let windgusts_10m_max: [Double]?
    let temperature_2m_max: [Double]?
    let temperature_2m_min: [Double]?
    let precipitation_sum: [Double]?
    let precipitation_probability_max: [Int]?
}

class WeatherService: ObservableObject {
    @Published var weather: WeatherData?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchWeather(lat: Double, lon: Double) {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&hourly=temperature_2m,precipitation,weathercode,winddirection_10m,cloudcover,sunshine_duration,is_day&daily=sunrise,sunset,windgusts_10m_max,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max&current_weather=true&forecast_days=3&timezone=auto"
        
        guard let url = URL(string: urlString) else { return }
        
        isLoading = true
        errorMessage = nil
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else { return }
                
                do {
                    let decoder = JSONDecoder()
                    let result = try decoder.decode(WeatherData.self, from: data)
                    self?.weather = result
                } catch {
                    self?.errorMessage = "Failed to parse weather: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}