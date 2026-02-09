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
            
            VStack(spacing: 0) {
                // Title
                Text("Detailed Weather")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(useNightMode ? .red : .white)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // Current Details Box
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
                        
                        // 3-Day Forecast Section
                        VStack(spacing: 12) {
                            Text("3-Day Forecast")
                                .font(.headline)
                                .foregroundColor(useNightMode ? .red : .white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.bottom, 4)
                            
                            ForEach(summary.dailyForecasts) { day in
                                HStack {
                                    // Date
                                    Text(day.dateStr)
                                        .fontWeight(.semibold)
                                        .foregroundColor(useNightMode ? .red : .white)
                                        .frame(width: 90, alignment: .leading)
                                    
                                    Spacer()
                                    
                                    // Temp Range
                                    Text("\(formatTemp(day.minTemp)) / \(formatTemp(day.maxTemp))")
                                        .foregroundColor(useNightMode ? .red : .white)
                                    
                                    Spacer()
                                    
                                    // Precip / Gusts
                                    VStack(alignment: .trailing) {
                                        if day.precipTotal > 0.1 {
                                            Text(formatPrecip(day.precipTotal))
                                                .font(.caption)
                                                .foregroundColor(useNightMode ? .red.opacity(0.8) : .teal)
                                        } else {
                                            Text("Dry")
                                                .font(.caption)
                                                .foregroundColor(useNightMode ? .red.opacity(0.6) : .secondary)
                                        }
                                        
                                        if day.maxGusts > 20 {
                                            Text("\(formatSpeed(day.maxGusts)) \(day.maxGustsDirection)")
                                                .font(.caption2)
                                                .foregroundColor(useNightMode ? .red.opacity(0.8) : .orange)
                                        }
                                    }
                                    .frame(width: 70, alignment: .trailing)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(useNightMode ? .red : .teal)
                .padding()
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(10)
                .padding(.bottom)
            }
        }
    }
    
    // Helpers copied from ContentView
    private func formatSpeed(_ kmh: Double) -> String {
        if useImperial {
            let mph = kmh * 0.621371
            return String(format: "%.1f mph", mph)
        } else {
            return String(format: "%.1f km/h", kmh)
        }
    }
    
    private func formatTemp(_ celsius: Double) -> String {
        if useImperial {
            let f = (celsius * 9/5) + 32
            return String(format: "%.0f°", f)
        } else {
            return String(format: "%.0f°", celsius)
        }
    }
    
    private func formatPrecip(_ mm: Double) -> String {
        if useImperial {
            let inches = mm * 0.0393701
            return String(format: "%.2f\"", inches)
        } else {
            return String(format: "%.1fmm", mm)
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