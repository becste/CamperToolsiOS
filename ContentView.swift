import SwiftUI
import CoreLocation

struct SettingsView: View {
    @ObservedObject var motionManager: MotionManager
    
    @AppStorage("bumpHeightMm") private var bumpHeightMm: Double = 0.0
    @AppStorage("compensationAppliesToRoll") private var compensationAppliesToRoll: Bool = false
    @AppStorage("useImperial") private var useImperial: Bool = false
    @AppStorage("useNightMode") private var useNightMode: Bool = false
    @Environment(\.dismiss) var dismiss
    
    // Constant shared with ContentView
    let DEFAULT_SUPPORT_SPAN_MM: Double = 70.0
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Level Calibration")) {
                    HStack {
                        Text("Bump Height (mm)")
                        Spacer()
                        TextField("0", value: $bumpHeightMm, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Toggle("Compensation applies to Roll", isOn: $compensationAppliesToRoll)
                    
                    Button(action: calibrate) {
                        HStack {
                            Image(systemName: "level")
                            Text("Auto Calibrate (Zero Current Tilt)")
                        }
                    }
                }
                
                Section(header: Text("Units & Appearance")) {
                    Toggle("Use Imperial Units", isOn: $useImperial)
                    Toggle("Night Mode", isOn: $useNightMode)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    private func calibrate() {
        // We want to find h (bumpHeightMm) such that the offset cancels out the current gravity reading.
        // Formula derived from: gravity = h / sqrt(h^2 + s^2)
        // Solved for h: h = (gravity * s) / sqrt(1 - gravity^2)
        
        let s = DEFAULT_SUPPORT_SPAN_MM
        // Use X (Roll) or Y (Pitch) depending on toggle
        let g = compensationAppliesToRoll ? motionManager.gravityX : motionManager.gravityY
        
        // Clamp g to avoid division by zero or imaginary numbers if sensor is crazy
        let clampedG = max(-0.99, min(0.99, g))
        
        let h = (clampedG * s) / sqrt(1 - clampedG * clampedG)
        
        // Update storage
        bumpHeightMm = h
    }
}

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var motionManager = MotionManager()
    @StateObject private var weatherService = WeatherService()
    @StateObject private var flashlightManager = FlashlightManager()
    
    @AppStorage("useImperial") private var useImperial: Bool = false
    @AppStorage("useNightMode") private var useNightMode: Bool = false
    @AppStorage("bumpHeightMm") private var bumpHeightMm: Double = 0.0
    @AppStorage("compensationAppliesToRoll") private var compensationAppliesToRoll: Bool = false
    
    @State private var showCompass = false
    @State private var showSettings = false
    @State private var showWeatherDetail = false
    @State private var flashlightBrightness: Float = 1.0
    
    #if targetEnvironment(simulator)
    @State private var debugHeading: Double = 0.0
    #endif
    
    // Constants
    let DEFAULT_SUPPORT_SPAN_MM: Double = 70.0 // from Android source
    
    var body: some View {
        ZStack {
            // Background
            (useNightMode ? Color.black : Color(white: 0.15))
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header: Elevation & Status
                VStack {
                    if let location = locationManager.location {
                        let altitude = location.altitude
                        let elevationText = formatElevation(altitude)
                        Text(elevationText)
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(useNightMode ? .red : .white)
                        
                        Text("GPS: Accurate to \(Int(location.horizontalAccuracy))m")
                            .font(.caption)
                            .foregroundColor(useNightMode ? .red.opacity(0.7) : .secondary)
                    } else {
                        Text("Getting Elevation...")
                            .font(.title2)
                            .foregroundColor(useNightMode ? .red : .white)
                    }
                }
                .padding(.top)
                
                // Weather Section
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Weather")
                            .font(.headline)
                        Spacer()
                        Button(action: {
                            if let loc = locationManager.location {
                                weatherService.fetchWeather(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude)
                            } else {
                                locationManager.requestLocation()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    
                    if weatherService.isLoading {
                        Text("Loading weather...")
                    } else if let weather = weatherService.weather, let summary = WeatherHelper.process(weather, useImperial: useImperial) {
                        
                        // Row 1: Current Temp & Wind
                        HStack {
                            Text("Now: \(formatTemp(summary.nowTemp))")
                                .font(.title3)
                            Spacer()
                            Text("Wind: \(formatSpeed(summary.windSpeed)) \(summary.windDirection)")
                        }
                        
                        // Row 2: Range
                        Text("Next 24h: \(formatTemp(summary.minTemp24h)) / \(formatTemp(summary.maxTemp24h))")
                            .font(.subheadline)
                        
                        // Row 3: Precip
                        HStack {
                            Text("Precip: \(summary.precipDescription)")
                                .font(.caption)
                            if summary.precipTotal > 0.05 {
                                Text("(\(formatPrecip(summary.precipTotal)))")
                                    .font(.caption)
                            }
                            Spacer()
                            Button("More Data") {
                                showWeatherDetail = true
                            }
                            .font(.caption)
                            .foregroundColor(useNightMode ? .red : .teal)
                        }
                        .padding(.top, 4)
                        
                    } else if let error = weatherService.errorMessage {
                        Text("Error: \(error)")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else {
                        Text("Tap refresh for weather")
                            .font(.caption)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(10)
                .foregroundColor(useNightMode ? .red : .white)
                
                // Level / Compass Toggle
                HStack(spacing: 0) {
                    Button(action: { showCompass = false }) {
                        Text("Level")
                            .font(.headline)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                !showCompass ? (useNightMode ? Color.red : Color.teal) : Color.clear
                            )
                            .foregroundColor(
                                !showCompass ? Color.black : (useNightMode ? Color.red : Color.white)
                            )
                    }
                    
                    Button(action: { showCompass = true }) {
                        Text("Compass")
                            .font(.headline)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                showCompass ? (useNightMode ? Color.red : Color.teal) : Color.clear
                            )
                            .foregroundColor(
                                showCompass ? Color.black : (useNightMode ? Color.red : Color.white)
                            )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(useNightMode ? Color.red : Color.teal, lineWidth: 1)
                )
                .padding(.horizontal)
                
                // Main View
                ZStack {
                    if showCompass {
                        if let heading = locationManager.heading?.trueHeading {
                            CompassView(heading: heading, isNightMode: useNightMode)
                            VStack {
                                Spacer()
                                Text("\(Int(heading))° \(cardinalDirection(heading))")
                                    .font(.title2)
                                    .foregroundColor(useNightMode ? .red : .white)
                            }
                        } else {
                            Text("Waiting for Heading...")
                                .foregroundColor(useNightMode ? .red : .white)
                        }
                    } else {
                        // Calculate tilt with compensation
                        let (tiltX, tiltY) = calculateTilt()
                        
                        LevelView(tiltX: tiltX, tiltY: tiltY, isNightMode: useNightMode)
                        
                        VStack {
                            Spacer()
                            // Calculate degrees
                            let pitch = -asin(max(-1, min(1, tiltY))) * 180 / .pi
                            let roll = asin(max(-1, min(1, tiltX))) * 180 / .pi
                            
                            Text(String(format: "Pitch: %.1f°  Roll: %.1f°", pitch, roll))
                                .font(.title3)
                                .foregroundColor(useNightMode ? .red : .white)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
                
                // Flashlight Controls
                VStack {
                    Toggle(isOn: $flashlightManager.isFlashlightOn) {
                        Text("Flashlight")
                            .foregroundColor(useNightMode ? .red : .white)
                    }
                    .tint(useNightMode ? .red : .teal)
                    .onChange(of: flashlightManager.isFlashlightOn) { newValue in
                        flashlightManager.setFlashlight(on: newValue, brightness: flashlightBrightness)
                    }
                    
                    if flashlightManager.isFlashlightOn {
                        Slider(value: $flashlightBrightness, in: 0.01...1.0)
                            .accentColor(useNightMode ? .red : .teal)
                            .onChange(of: flashlightBrightness) { newValue in
                                flashlightManager.setFlashlight(on: true, brightness: newValue)
                            }
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(10)
                
                HStack {
                    Spacer()
                    Button("Settings") {
                        showSettings = true
                    }
                    .foregroundColor(useNightMode ? .red : .teal)
                }
                .padding()
            }
            .padding()
        }
        .onShake {
            flashlightManager.toggle()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(motionManager: motionManager)
        }
        .sheet(isPresented: $showWeatherDetail) {
            if let weather = weatherService.weather, let summary = WeatherHelper.process(weather, useImperial: useImperial) {
                WeatherDetailView(summary: summary, useImperial: useImperial, useNightMode: useNightMode)
            }
        }
        .onAppear {
            locationManager.requestPermission()
            locationManager.startUpdates()
            motionManager.startUpdates()
        }
    }
    
    // MARK: - Helpers
    
    private func formatElevation(_ meters: Double) -> String {
        if useImperial {
            let feet = meters * 3.28084
            return String(format: "%.0f ft", feet)
        } else {
            return String(format: "%.0f m", meters)
        }
    }
    
    private func formatTemp(_ celsius: Double) -> String {
        if useImperial {
            let f = (celsius * 9/5) + 32
            return String(format: "%.1f°F", f)
        } else {
            return String(format: "%.1f°C", celsius)
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
    
    private func formatPrecip(_ mm: Double) -> String {
        if useImperial {
            let inches = mm * 0.0393701
            return String(format: "%.2f\"", inches)
        } else {
            return String(format: "%.1f mm", mm)
        }
    }
    
    private func cardinalDirection(_ heading: Double) -> String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((heading + 22.5) / 45.0) & 7
        return directions[index]
    }
    
    private func calculateTilt() -> (Double, Double) {
        // Raw values from MotionManager (Gravity vector)
        // iOS Gravity: x (right), y (up), z (face)
        // Android Code Mapping Logic:
        // normX = ax / g.
        // Android LevelView uses normX for "Horizontal Bar" (Side to side tilt) -> Roll
        // Android LevelView uses normY for "Vertical Bar" (Front to back tilt) -> Pitch
        
        // MotionManager gravity.x corresponds to Roll component
        // MotionManager gravity.y corresponds to Pitch component
        
        let rawX = motionManager.gravityX
        let rawY = motionManager.gravityY
        
        // Smoothing is done by CMMotionManager internally usually better than raw accel
        // But Android code had smoothing. We'll use raw for now as DeviceMotion is already fused/smooth.
        
        // Bump Compensation
        // float compensationMagnitude = computeNormalizedOffset(...)
        // if (compensationAppliesToRoll) offsetX = sign * magnitude
        // else offsetY = sign * magnitude
        
        var offsetX = 0.0
        var offsetY = 0.0
        
        if bumpHeightMm != 0 {
             let denom = sqrt(bumpHeightMm * bumpHeightMm + DEFAULT_SUPPORT_SPAN_MM * DEFAULT_SUPPORT_SPAN_MM)
             if denom != 0 {
                 let magnitude = bumpHeightMm / denom
                 let sign = bumpHeightMm > 0 ? 1.0 : -1.0 // Sign logic from Android seemed slightly redundant with abs, but let's follow.
                 // Actually Android: float sign = Math.signum(lastBumpHeightMm);
                 // compensationMagnitude = compute... (uses abs).
                 // So magnitude is always positive. Offset takes sign.
                 
                 let offsetVal = sign * abs(magnitude)
                 
                 if compensationAppliesToRoll {
                     offsetX = offsetVal
                 } else {
                     offsetY = offsetVal
                 }
             }
        }
        
        // Apply offset
        let finalX = rawX - offsetX
        let finalY = rawY - offsetY
        
        return (finalX, finalY)
    }
}

#Preview {
    ContentView()
}