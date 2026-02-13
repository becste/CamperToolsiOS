import Foundation

enum UnitFormatting {
    static func elevation(_ meters: Double, useImperial: Bool) -> String {
        if useImperial {
            let feet = meters * 3.28084
            return String(format: "%.0f ft", feet)
        }
        return String(format: "%.0f m", meters)
    }

    static func temperature(_ celsius: Double, useImperial: Bool, decimals: Int = 1, includeUnit: Bool = true) -> String {
        let value: Double
        let unit: String

        if useImperial {
            value = (celsius * 9 / 5) + 32
            unit = includeUnit ? "\u{00B0}F" : "\u{00B0}"
        } else {
            value = celsius
            unit = includeUnit ? "\u{00B0}C" : "\u{00B0}"
        }

        return String(format: "%.\(decimals)f%@", value, unit)
    }

    static func speed(_ kmh: Double, useImperial: Bool) -> String {
        if useImperial {
            let mph = kmh * 0.621371
            return String(format: "%.1f mph", mph)
        }
        return String(format: "%.1f km/h", kmh)
    }

    static func precipitation(_ millimeters: Double, useImperial: Bool) -> String {
        if useImperial {
            let inches = millimeters * 0.0393701
            return String(format: "%.2f\"", inches)
        }
        return String(format: "%.1f mm", millimeters)
    }

    static func shimHeight(_ value: Double, useImperial: Bool) -> String {
        if useImperial {
            return String(format: "%.1f\"", value)
        }
        return String(format: "%.1f cm", value)
    }
}
