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
                            
                            DetailRow(label: "Wind Gusts", value: "\(UnitFormatting.speed(summary.maxGusts, useImperial: useImperial)) \(summary.maxGustsDirection)", isNight: useNightMode)
                            
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
                                    Text("\(UnitFormatting.temperature(day.minTemp, useImperial: useImperial, decimals: 0, includeUnit: false)) / \(UnitFormatting.temperature(day.maxTemp, useImperial: useImperial, decimals: 0, includeUnit: false))")
                                        .foregroundColor(useNightMode ? .red : .white)
                                    
                                    Spacer()
                                    
                                    // Precip / Gusts
                                    VStack(alignment: .trailing) {
                                        if day.precipTotal > 0.1 {
                                            Text(UnitFormatting.precipitation(day.precipTotal, useImperial: useImperial))
                                                .font(.caption)
                                                .foregroundColor(useNightMode ? .red.opacity(0.8) : .teal)
                                        } else {
                                            Text("Dry")
                                                .font(.caption)
                                                .foregroundColor(useNightMode ? .red.opacity(0.6) : .white)
                                        }
                                        
                                        if day.maxGusts > 20 {
                                            Text("\(UnitFormatting.speed(day.maxGusts, useImperial: useImperial)) \(day.maxGustsDirection)")
                                                .font(.caption2)
                                                .foregroundColor(useNightMode ? .red.opacity(0.8) : .orange)
                                                .lineLimit(1)
                                                .fixedSize(horizontal: true, vertical: false)
                                        }
                                    }
                                    .frame(width: 85, alignment: .trailing)
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
