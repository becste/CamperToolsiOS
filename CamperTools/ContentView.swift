import SwiftUI
import CoreLocation
import StoreKit
import Combine

struct SettingsView: View {
    @ObservedObject var motionManager: MotionManager
    @Binding var debugSimulateCompass: Bool // Simulator only
    
    // Calibration Offsets (Zero Points)
    @AppStorage("calibPitch") private var calibPitch: Double = 0.0
    @AppStorage("calibRoll") private var calibRoll: Double = 0.0
    
    @AppStorage("useImperial") private var useImperial: Bool = false
    @AppStorage("useNightMode") private var useNightMode: Bool = false
    @Environment(\.dismiss) var dismiss
    
    @State private var showHelp = false
    
    // Computed Bindings for UI (Degrees)
    private var pitchDegrees: Binding<Double> {
        Binding(
            get: { 
                let val = max(-1, min(1, calibPitch))
                return asin(val) * 180 / .pi 
            },
            set: { calibPitch = sin($0 * .pi / 180) }
        )
    }
    
    private var rollDegrees: Binding<Double> {
        Binding(
            get: { 
                let val = max(-1, min(1, calibRoll))
                return asin(val) * 180 / .pi 
            },
            set: { calibRoll = sin($0 * .pi / 180) }
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                (useNightMode ? Color.black : Color(white: 0.15))
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        
                        // Section: Level Calibration
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Level Calibration")
                                .font(.headline)
                                .foregroundColor(useNightMode ? .red : .white)
                            
                            Text("Adjust the offsets manually (in degrees) or use Auto Calibrate to zero-out the current tilt.")
                                .font(.caption)
                                .foregroundColor(useNightMode ? .red.opacity(0.8) : .secondary)

                            // Manual Pitch
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Pitch Offset (Degrees)")
                                TextField("0.0°", value: pitchDegrees, format: .number.precision(.fractionLength(1)))
                                    .keyboardType(.decimalPad)
                                    .padding(8)
                                    .background(Color.secondary.opacity(0.2))
                                    .cornerRadius(5)
                                    .foregroundColor(useNightMode ? .red : .white)
                            }
                            .foregroundColor(useNightMode ? .red : .white)
                            
                            // Manual Roll
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Roll Offset (Degrees)")
                                TextField("0.0°", value: rollDegrees, format: .number.precision(.fractionLength(1)))
                                    .keyboardType(.decimalPad)
                                    .padding(8)
                                    .background(Color.secondary.opacity(0.2))
                                    .cornerRadius(5)
                                    .foregroundColor(useNightMode ? .red : .white)
                            }
                            .foregroundColor(useNightMode ? .red : .white)
                            
                            // Buttons
                            HStack(spacing: 20) {
                                Button(action: calibrate) {
                                    HStack {
                                        Image(systemName: "level")
                                        Text("Auto Calibrate")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.secondary.opacity(0.2))
                                    .foregroundColor(useNightMode ? .red : .teal)
                                    .cornerRadius(10)
                                }
                                
                                Button(action: reset) {
                                    Text("Reset")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.red.opacity(0.2))
                                        .foregroundColor(.red)
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Section: Units & Appearance
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Units & Appearance")
                                .font(.headline)
                                .foregroundColor(useNightMode ? .red : .white)
                            
                            Toggle("Use Imperial Units", isOn: $useImperial)
                                .foregroundColor(useNightMode ? .red : .white)
                                .tint(useNightMode ? .red : .teal)
                            
                            Toggle("Night Mode", isOn: $useNightMode)
                                .foregroundColor(useNightMode ? .red : .white)
                                .tint(useNightMode ? .red : .teal)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Section: Help
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Support")
                                .font(.headline)
                                .foregroundColor(useNightMode ? .red : .white)
                            
                            Button(action: { showHelp = true }) {
                                HStack {
                                    Image(systemName: "questionmark.circle")
                                    Text("Help")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.secondary.opacity(0.2))
                                .foregroundColor(useNightMode ? .red : .teal)
                                .cornerRadius(10)
                            }
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(12)
                        
                        Button(action: { dismiss() }) {
                            Text("Save & Done")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.secondary.opacity(0.2))
                                .foregroundColor(useNightMode ? .red : .teal)
                                .cornerRadius(10)
                        }
                        
                        #if targetEnvironment(simulator)
                        // Section: Debug (Simulator Only)
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Simulator Debug")
                                .font(.headline)
                                .foregroundColor(.orange)
                            
                            Toggle("Test Compass (Auto-Rotate)", isOn: $debugSimulateCompass)
                                .foregroundColor(useNightMode ? .red : .white)
                                .tint(.orange)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(12)
                        #endif
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showHelp) {
                HelpView()
            }
            .toolbar {
                // Toolbar item removed to move button to bottom
            }
        }
        // Force the Navigation Bar appearance to match
        .onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = useNightMode ? .black : UIColor(white: 0.15, alpha: 1.0)
            appearance.titleTextAttributes = [.foregroundColor: useNightMode ? UIColor.red : UIColor.white]
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    private func calibrate() {
        // Set zero point to current gravity reading
        calibPitch = motionManager.gravityY
        calibRoll = motionManager.gravityX
    }
    
    private func reset() {
        calibPitch = 0.0
        calibRoll = 0.0
    }
}

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var motionManager = MotionManager()
    @StateObject private var weatherService = WeatherService()
    @StateObject private var flashlightManager = FlashlightManager()
    @StateObject private var storeManager = StoreManager() // IAP Manager
    
    @AppStorage("useImperial") private var useImperial: Bool = false
    @AppStorage("useNightMode") private var useNightMode: Bool = false
    
    // Replaced old Bump calibration with direct offsets
    @AppStorage("calibPitch") private var calibPitch: Double = 0.0
    @AppStorage("calibRoll") private var calibRoll: Double = 0.0
    
    @AppStorage("isFirstLaunch") private var isFirstLaunch: Bool = true
    
    @State private var showCompass = false
    @State private var showSettings = false
    @State private var showWeatherDetail = false
    @State private var showWheelAdjust = false
    @State private var showHelp = false
    @State private var flashlightBrightness: Float = 1.0
    
    @State private var debugSimulateCompass = false // Controlled by Settings in Simulator
    @State private var simulatedHeading = 0.0
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
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
                        
                    } else {
                        Text("Tap refresh for weather")
                            .font(.caption)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(10)
                .foregroundColor(useNightMode ? .red : .white)
                
                // Show Compass Toggle
                Toggle("Show Compass", isOn: $showCompass)
                    .padding()
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .foregroundColor(useNightMode ? .red : .white)
                    .tint(useNightMode ? .red : .teal)
                
                // Main View
                ZStack {
                    if showCompass {
                        // Compute heading to display as a pure expression to keep ViewBuilder happy
                        let displayHeading: Double? = {
                            if debugSimulateCompass {
                                return simulatedHeading
                            } else if let h = locationManager.heading?.trueHeading {
                                return h
                            } else {
                                return nil
                            }
                        }()
                        
                        if let heading = displayHeading {
                            VStack(spacing: 12) {
                                // Smaller compass centered
                                GeometryReader { geo in
                                    let side = min(geo.size.width, geo.size.height) * 0.7
                                    CompassView(heading: heading, isNightMode: useNightMode)
                                        .frame(width: side, height: side)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                
                                Text("\(Int(heading))° \(cardinalDirection(heading))")
                                    .font(.title2)
                                    .foregroundColor(useNightMode ? .red : .white)
                                    .padding(.bottom, 8)
                            }
                        } else {
                            Text("Waiting for Heading...")
                                .foregroundColor(useNightMode ? .red : .white)
                        }
                    } else {
                        // Calculate tilt with compensation
                        let (tiltX, tiltY) = calculateTilt()
                        
                        ZStack(alignment: .topTrailing) {
                            LevelView(tiltX: tiltX, tiltY: tiltY, isNightMode: useNightMode)
                            
                            Button(action: { showWheelAdjust = true }) {
                                Text("Height\nAdjust")
                                    .font(.caption2.bold())
                                    .multilineTextAlignment(.center)
                                    .padding(8)
                                    .background(Color.secondary.opacity(0.2))
                                    .foregroundColor(useNightMode ? .red : .teal)
                                    .cornerRadius(8)
                            }
                            .padding(.trailing, 10)
                            .padding(.top, 10)
                        }
                        
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
                
                // Buttons Row (Donate + Settings)
                HStack(spacing: 20) {
                    // Donate on the left now
                    if let product = storeManager.products.first {
                        Button(action: {
                            Task { await storeManager.purchase(product) }
                        }) {
                            HStack {
                                Image(systemName: "cup.and.saucer.fill")
                                Text("Donate")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(useNightMode ? .red : .teal)
                        .padding()
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(10)
                    } else {
                        // Fallback text if loading or no products
                        if let error = storeManager.errorMessage {
                            Text(error)
                                .font(.caption2)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Loading...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button("Settings") {
                        showSettings = true
                    }
                    .font(.headline)
                    .foregroundColor(useNightMode ? .red : .teal)
                    .padding()
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(10)
                }
                .padding(.bottom, 5)
                
                // Attribution - Bottom of Screen
                Link("Weather data by Open-Meteo.com", destination: URL(string: "https://open-meteo.com/")!)
                    .font(.caption2)
                    .foregroundColor(useNightMode ? .red.opacity(0.7) : .teal)
                    .padding(.bottom, 5)
            }
            .padding()
        }
        .onShake {
            flashlightManager.toggle()
        }
        .onReceive(timer) { _ in
            if debugSimulateCompass {
                simulatedHeading += 1.0
                if simulatedHeading > 360 { simulatedHeading = 0 }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(motionManager: motionManager, debugSimulateCompass: $debugSimulateCompass)
        }
        .sheet(isPresented: $showWeatherDetail) {
            if let weather = weatherService.weather, let summary = WeatherHelper.process(weather, useImperial: useImperial) {
                WeatherDetailView(summary: summary, useImperial: useImperial, useNightMode: useNightMode)
            }
        }
        .sheet(isPresented: $showWheelAdjust) {
            WheelAdjustView(motionManager: motionManager)
        }
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
        .onAppear {
            if isFirstLaunch {
                showHelp = true
                isFirstLaunch = false
            }
            locationManager.requestPermission()
            locationManager.startUpdates()
            motionManager.startUpdates()
            Task {
                await storeManager.loadProducts()
            }
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
        let rawX = motionManager.gravityX
        let rawY = motionManager.gravityY
        
        // Apply calibration offsets
        let finalX = rawX - calibRoll
        let finalY = rawY - calibPitch
        
        return (finalX, finalY)
    }
}

#Preview {
    ContentView()
}