#if canImport(XCTest) && canImport(CamperToolsCore)
import XCTest
@testable import CamperToolsCore

final class WeatherHelperTests: XCTestCase {
    func testProcessUsesTimelineForRolling24hWindow() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"

        let baseDate = formatter.date(from: "2026-01-01T06:00")!
        let now = formatter.date(from: "2026-01-01T06:30")!

        let count = 30
        let times = (0..<count).map {
            formatter.string(from: baseDate.addingTimeInterval(Double($0) * 3600.0))
        }
        let temps = (0..<count).map(Double.init)

        let weather = WeatherData(
            current_weather: CurrentWeather(temperature: 10, windspeed: 20, winddirection: 180, weathercode: 1),
            hourly: HourlyUnits(
                time: times,
                temperature_2m: temps,
                precipitation: Array(repeating: 0, count: count),
                weathercode: Array(repeating: 1, count: count),
                winddirection_10m: Array(repeating: 180, count: count),
                cloudcover: Array(repeating: 50, count: count),
                sunshine_duration: Array(repeating: 1800, count: count),
                is_day: Array(repeating: 1, count: count)
            ),
            daily: DailyUnits(
                time: ["2026-01-01", "2026-01-02", "2026-01-03", "2026-01-04"],
                sunrise: ["2026-01-01T07:30"],
                sunset: ["2026-01-01T17:30"],
                windgusts_10m_max: [35, 20, 15, 10],
                temperature_2m_max: [15, 16, 17, 18],
                temperature_2m_min: [5, 6, 7, 8],
                precipitation_sum: [0, 1, 2, 3],
                precipitation_probability_max: [0, 25, 45, 60],
                winddirection_10m_dominant: [180, 190, 200, 210]
            )
        )

        guard let summary = WeatherHelper.process(weather, useImperial: false, now: now) else {
            XCTFail("Expected weather summary")
            return
        }

        XCTAssertEqual(summary.minTemp24h, 1, accuracy: 0.001)
        XCTAssertEqual(summary.maxTemp24h, 24, accuracy: 0.001)
    }
}
#endif
