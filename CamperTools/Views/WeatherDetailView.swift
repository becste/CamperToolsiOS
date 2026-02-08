import SwiftUI

struct WeatherDetailView: View {
    let summary: WeatherSummary
    let useImperial: Bool
    let useNightMode: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            (useNightMode ? Color.black : Color(white: 0.15))
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Detailed Weather")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(useNightMode ? .red : .white)
                    .padding(.top)
                
                VStack(spacing: 16) {
                    DetailRow(label: "Sunrise", value: summary.sunrise, isNight: useNightMode)
                    DetailRow(label: "Sunset", value: summary.sunset, isNight: useNightMode)
                    
                    Divider()
                        .frame(height: 1)
                        .background(useNightMode ? Color.red.opacity(0.5) : Color.white.opacity(0.3))
                    
                    DetailRow(label: "Max Gusts (24h)", value: formatSpeed(summary.maxGusts), isNight: useNightMode)
                    
                    DetailRow(label: "Sunshine (24h)", value: String(format: "%.1fh (%.0f%%)", summary.sunshineHours, summary.sunshinePercent), isNight: useNightMode)
                    
                    DetailRow(label: "Cloud Cover (avg)", value: String(format: "%.0f%%", summary.avgCloudCover), isNight: useNightMode)
                }
                .padding()
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(useNightMode ? .red : .teal)
                .padding()
            }
        }
    }
    
    private func formatSpeed(_ kmh: Double) -> String {
        if useImperial {
            let mph = kmh * 0.621371
            return String(format: "%.1f mph", mph)
        } else {
            return String(format: "%.1f km/h", kmh)
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    let isNight: Bool
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(isNight ? .red : .white.opacity(0.8))
            Spacer()
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(isNight ? .red : .white)
        }
    }
}
