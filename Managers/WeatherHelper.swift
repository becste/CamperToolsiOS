import Foundation

struct DailyForecast: Identifiable {
    let id = UUID()
    let dateStr: String
    let minTemp: Double
    let maxTemp: Double
    let precipTotal: Double
    let precipProb: Int
    let maxGusts: Double
    let maxGustsDirection: String
}

struct WeatherSummary {
    let nowTemp: Double
    let minTemp24h: Double
    let maxTemp24h: Double
    let windSpeed: Double
    let windDirection: String
    let precipTotal: Double
    let precipDescription: String

    // Detail / Sun Data
    let sunrise: String
    let sunset: String
    let maxGusts: Double
    let maxGustsDirection: String
    let sunshineHours: Double
    let sunshinePercent: Double
    let avgCloudCover: Double

    // 3-Day Forecast
    let dailyForecasts: [DailyForecast]
}

final class WeatherHelper {
    private static let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]

    private static let hourlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func process(_ data: WeatherData, useImperial: Bool, now: Date = Date()) -> WeatherSummary? {
        let hourly = data.hourly
        let baseCount = [
            hourly.time.count,
            hourly.temperature_2m.count,
            hourly.precipitation.count,
            hourly.weathercode.count,
            hourly.winddirection_10m.count
        ].min() ?? 0

        guard baseCount > 0 else { return nil }

        let parsedTimes = Array(hourly.time.prefix(baseCount)).map { parseDateTime($0) }
        let startIdx = parsedTimes.enumerated().first(where: { _, date in
            guard let date else { return false }
            return date >= now
        })?.offset ?? max(0, baseCount - 1)

        let endIdx = min(baseCount, startIdx + 24)
        guard startIdx < endIdx else { return nil }

        var minT = hourly.temperature_2m[startIdx]
        var maxT = hourly.temperature_2m[startIdx]
        var sumPrecip = 0.0

        var anySnow = false
        var anyThunder = false
        var anyFreezing = false

        for i in startIdx..<endIdx {
            let t = hourly.temperature_2m[i]
            let p = hourly.precipitation[i]
            let code = hourly.weathercode[i]
            minT = min(minT, t)
            maxT = max(maxT, t)
            sumPrecip += p

            if [71, 73, 75, 77, 85, 86].contains(code) { anySnow = true }
            if [95, 96, 99].contains(code) { anyThunder = true }
            if [56, 57, 66, 67].contains(code) { anyFreezing = true }
        }

        let precipDesc: String
        if sumPrecip < 0.05 {
            precipDesc = "None"
        } else {
            let type: String
            if anyThunder { type = "Rain with Thunder" }
            else if anySnow { type = "Snow / Wintry" }
            else if anyFreezing { type = "Mix / Freezing" }
            else { type = "Rain" }

            let intensity: String
            if sumPrecip < 1.0 { intensity = "Very Light" }
            else if sumPrecip < 5.0 { intensity = "Light" }
            else if sumPrecip < 15.0 { intensity = "Moderate" }
            else { intensity = "Heavy" }

            precipDesc = "\(intensity) \(type)"
        }

        let sunriseRaw = data.daily.sunrise.first ?? ""
        let sunsetRaw = data.daily.sunset.first ?? ""

        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.timeZone = .current
        timeFormatter.dateFormat = useImperial ? "h:mm a" : "HH:mm"

        let sunriseStr = parseDateTime(sunriseRaw).map { timeFormatter.string(from: $0) } ?? sunriseRaw
        let sunsetStr = parseDateTime(sunsetRaw).map { timeFormatter.string(from: $0) } ?? sunsetRaw

        let maxGusts = data.daily.windgusts_10m_max?[safe: 0] ?? 0.0
        let maxGustDirection = getCardinalDirection(data.daily.winddirection_10m_dominant?[safe: 0] ?? 0.0)

        var totalSunshineSec = 0.0
        var totalDaylightSec = 0.0
        var sumCloud = 0.0
        var cloudCount = 0

        if let sunArr = hourly.sunshine_duration,
           let isDayArr = hourly.is_day,
           let cloudArr = hourly.cloudcover {
            let limit = [sunArr.count, isDayArr.count, cloudArr.count, baseCount].min() ?? 0
            let loopEnd = min(limit, startIdx + 24)

            if startIdx < loopEnd {
                for i in startIdx..<loopEnd {
                    totalSunshineSec += sunArr[i]
                    if isDayArr[i] == 1 {
                        totalDaylightSec += 3600.0
                    }
                    sumCloud += cloudArr[i]
                    cloudCount += 1
                }
            }
        }

        let sunshineHours = totalSunshineSec / 3600.0
        let sunshinePercent = totalDaylightSec > 0 ? (totalSunshineSec / totalDaylightSec) * 100.0 : 0.0
        let avgCloud = cloudCount > 0 ? sumCloud / Double(cloudCount) : 0.0

        var forecasts: [DailyForecast] = []
        let daily = data.daily
        let dailyCount = daily.time.count

        let dateOutputFormatter = DateFormatter()
        dateOutputFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateOutputFormatter.dateFormat = "EEE, MMM d"

        if dailyCount > 1 {
            for i in 1..<min(4, dailyCount) {
                let dateStrRaw = daily.time[i]
                let dateDisplay: String
                if let d = dayFormatter.date(from: dateStrRaw) {
                    dateDisplay = dateOutputFormatter.string(from: d)
                } else {
                    dateDisplay = dateStrRaw
                }

                let min = daily.temperature_2m_min?[safe: i] ?? 0.0
                let max = daily.temperature_2m_max?[safe: i] ?? 0.0
                let pSum = daily.precipitation_sum?[safe: i] ?? 0.0
                let pProb = daily.precipitation_probability_max?[safe: i] ?? 0
                let gust = daily.windgusts_10m_max?[safe: i] ?? 0.0
                let gustDirDeg = daily.winddirection_10m_dominant?[safe: i] ?? 0.0

                forecasts.append(DailyForecast(
                    dateStr: dateDisplay,
                    minTemp: min,
                    maxTemp: max,
                    precipTotal: pSum,
                    precipProb: pProb,
                    maxGusts: gust,
                    maxGustsDirection: getCardinalDirection(gustDirDeg)
                ))
            }
        }

        return WeatherSummary(
            nowTemp: data.current_weather.temperature,
            minTemp24h: minT,
            maxTemp24h: maxT,
            windSpeed: data.current_weather.windspeed,
            windDirection: getCardinalDirection(data.current_weather.winddirection),
            precipTotal: sumPrecip,
            precipDescription: precipDesc,
            sunrise: sunriseStr,
            sunset: sunsetStr,
            maxGusts: maxGusts,
            maxGustsDirection: maxGustDirection,
            sunshineHours: sunshineHours,
            sunshinePercent: sunshinePercent,
            avgCloudCover: avgCloud,
            dailyForecasts: forecasts
        )
    }

    private static func parseDateTime(_ raw: String) -> Date? {
        if let date = hourlyFormatter.date(from: raw) {
            return date
        }

        let isoFormatter = ISO8601DateFormatter()
        return isoFormatter.date(from: raw)
    }

    private static func getCardinalDirection(_ degrees: Double) -> String {
        let index = Int((degrees + 22.5) / 45.0) & 7
        return directions[index]
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
