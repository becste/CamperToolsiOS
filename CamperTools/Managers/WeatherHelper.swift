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
    let sunshineHours: Double
    let sunshinePercent: Double
    let avgCloudCover: Double
    
    // 3-Day Forecast
    let dailyForecasts: [DailyForecast]
}

class WeatherHelper {
    
    static func process(_ data: WeatherData, useImperial: Bool) -> WeatherSummary? {
        let dirs = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        
        func getCardinalDirection(_ degrees: Double) -> String {
            let index = Int((degrees + 22.5) / 45.0) & 7
            return dirs[index]
        }

        // 1. Determine Current Hour Index
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        
        let hourly = data.hourly
        let count = hourly.temperature_2m.count
        
        // Ensure we have enough data
        guard count > currentHour else { return nil }
        
        let startIdx = currentHour
        let endIdx = min(count, startIdx + 24)
        
        // ---- 24h Ranges (Temp, Precip) ----
        var minT = hourly.temperature_2m[startIdx]
        var maxT = hourly.temperature_2m[startIdx]
        var sumPrecip = 0.0
        
        // Wind Direction Buckets (8)
        var windBuckets = [Int](repeating: 0, count: 8)
        
        // Weather Codes
        var anySnow = false
        var anyThunder = false
        var anyFreezing = false
        
        for i in startIdx..<endIdx {
            let t = hourly.temperature_2m[i]
            let p = hourly.precipitation[i]
            let code = hourly.weathercode[i]
            let wDir = hourly.winddirection_10m[i]
            
            if t < minT { minT = t }
            if t > maxT { maxT = t }
            sumPrecip += p
            
            // Wind Bucket
            let bucket = Int((wDir + 22.5) / 45.0) & 7
            windBuckets[bucket] += 1
            
            // Codes
            if [71, 73, 75, 77, 85, 86].contains(code) { anySnow = true }
            if [95, 96, 99].contains(code) { anyThunder = true }
            if [56, 57, 66, 67].contains(code) { anyFreezing = true }
        }
        
        // Prevailing Wind Direction
        var maxBucketIdx = 0
        for i in 1..<8 {
            if windBuckets[i] > windBuckets[maxBucketIdx] {
                maxBucketIdx = i
            }
        }
        let prevailingDir = getCardinalDirection(Double(maxBucketIdx * 45))
        
        // Precip Description
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
        
        // ---- Sun / Detail Data ----
        let sunriseRaw = data.daily.sunrise.first ?? ""
        let sunsetRaw = data.daily.sunset.first ?? ""
        
        let isoFormatter = DateFormatter()
        isoFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = useImperial ? "h:mm a" : "HH:mm"
        
        let sunriseStr: String
        if let d = isoFormatter.date(from: sunriseRaw) {
            sunriseStr = timeFormatter.string(from: d)
        } else {
            sunriseStr = sunriseRaw
        }
        
        let sunsetStr: String
        if let d = isoFormatter.date(from: sunsetRaw) {
            sunsetStr = timeFormatter.string(from: d)
        } else {
            sunsetStr = sunsetRaw
        }
        
        // Max Gusts (Daily)
        let maxGusts = data.daily.windgusts_10m_max?.first ?? 0.0
        
        // Sunshine & Cloud Cover (Rolling 24h)
        var totalSunshineSec = 0.0
        var totalDaylightSec = 0.0
        var sumCloud = 0.0
        var cloudCount = 0
        
        if let sunArr = hourly.sunshine_duration, let isDayArr = hourly.is_day, let cloudArr = hourly.cloudcover {
             let limit = min(sunArr.count, min(isDayArr.count, cloudArr.count))
             let loopEnd = min(limit, startIdx + 24)
            
             for i in startIdx..<loopEnd {
                 totalSunshineSec += sunArr[i]
                 if isDayArr[i] == 1 {
                     totalDaylightSec += 3600.0
                 }
                 sumCloud += cloudArr[i]
                 cloudCount += 1
             }
        }
        
        let sunshineHours = totalSunshineSec / 3600.0
        let sunshinePercent = totalDaylightSec > 0 ? (totalSunshineSec / totalDaylightSec) * 100.0 : 0.0
        let avgCloud = cloudCount > 0 ? sumCloud / Double(cloudCount) : 0.0
        
        // ---- 3-Day Forecast ----
        var forecasts: [DailyForecast] = []
        let daily = data.daily
        let dateInputFormatter = DateFormatter()
        dateInputFormatter.dateFormat = "yyyy-MM-dd"
        let dateOutputFormatter = DateFormatter()
        dateOutputFormatter.dateFormat = "EEE, MMM d"
        
        let dailyCount = daily.time.count
        for i in 1..<min(4, dailyCount) {
            let dateStrRaw = daily.time[i]
            let dateDisplay: String
            if let d = dateInputFormatter.date(from: dateStrRaw) {
                dateDisplay = dateOutputFormatter.string(from: d)
            } else {
                dateDisplay = dateStrRaw
            }
            
            let min = daily.temperature_2m_min?[i] ?? 0.0
            let max = daily.temperature_2m_max?[i] ?? 0.0
            let pSum = daily.precipitation_sum?[i] ?? 0.0
            let pProb = daily.precipitation_probability_max?[i] ?? 0
            let gust = daily.windgusts_10m_max?[i] ?? 0.0
            let gustDirDeg = daily.winddirection_10m_dominant?[i] ?? 0.0
            
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
        
        return WeatherSummary(
            nowTemp: data.current_weather.temperature,
            minTemp24h: minT,
            maxTemp24h: maxT,
            windSpeed: data.current_weather.windspeed,
            windDirection: prevailingDir,
            precipTotal: sumPrecip,
            precipDescription: precipDesc,
            sunrise: sunriseStr,
            sunset: sunsetStr,
            maxGusts: maxGusts,
            sunshineHours: sunshineHours,
            sunshinePercent: sunshinePercent,
            avgCloudCover: avgCloud,
            dailyForecasts: forecasts
        )
    }
}