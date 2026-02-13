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
    let winddirection_10m_dominant: [Double]?
}

@MainActor
final class WeatherService: ObservableObject {
    @Published var weather: WeatherData?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var activeTask: URLSessionDataTask?

    func fetchWeather(lat: Double, lon: Double) {
        activeTask?.cancel()

        guard var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast") else {
            errorMessage = "Failed to build weather request URL."
            return
        }

        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(lat)),
            URLQueryItem(name: "longitude", value: String(lon)),
            URLQueryItem(name: "hourly", value: "temperature_2m,precipitation,weathercode,winddirection_10m,cloudcover,sunshine_duration,is_day"),
            URLQueryItem(name: "daily", value: "sunrise,sunset,windgusts_10m_max,winddirection_10m_dominant,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max"),
            URLQueryItem(name: "current_weather", value: "true"),
            URLQueryItem(name: "forecast_days", value: "4"),
            URLQueryItem(name: "timezone", value: "auto")
        ]

        guard let url = components.url else {
            errorMessage = "Failed to build weather request URL."
            return
        }

        isLoading = true
        errorMessage = nil

        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 20)

        activeTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            let result = Self.decodeWeatherResponse(data: data, response: response, error: error)

            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                self.activeTask = nil

                switch result {
                case .success(let weather):
                    self.weather = weather
                    self.errorMessage = nil
                case .failure(let serviceError):
                    if serviceError != .cancelled {
                        self.errorMessage = serviceError.localizedDescription
                    }
                }
            }
        }

        activeTask?.resume()
    }

    nonisolated private static func decodeWeatherResponse(
        data: Data?,
        response: URLResponse?,
        error: Error?
    ) -> Result<WeatherData, WeatherServiceError> {
        if let nsError = error as NSError? {
            if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
                return .failure(.cancelled)
            }
            return .failure(.requestFailed(nsError.localizedDescription))
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            return .failure(.invalidResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            return .failure(.httpStatus(httpResponse.statusCode))
        }

        guard let data, !data.isEmpty else {
            return .failure(.emptyData)
        }

        do {
            return .success(try JSONDecoder().decode(WeatherData.self, from: data))
        } catch {
            return .failure(.decoding(error.localizedDescription))
        }
    }
}

private enum WeatherServiceError: Error, Equatable {
    case cancelled
    case requestFailed(String)
    case invalidResponse
    case httpStatus(Int)
    case emptyData
    case decoding(String)
}

private extension WeatherServiceError {
    var localizedDescription: String {
        switch self {
        case .cancelled:
            return ""
        case .requestFailed(let message):
            return "Weather request failed: \(message)"
        case .invalidResponse:
            return "Weather service returned an invalid response."
        case .httpStatus(let code):
            return "Weather service returned status \(code)."
        case .emptyData:
            return "Weather service returned empty data."
        case .decoding(let message):
            return "Failed to parse weather: \(message)"
        }
    }
}
