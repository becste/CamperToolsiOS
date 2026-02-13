import SwiftUI
import CoreLocation
import Combine

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var locationManager = LocationManager()
    @StateObject private var motionManager = MotionManager()
    @StateObject private var weatherService = WeatherService()
    @StateObject private var flashlightManager = FlashlightManager()
    @StateObject private var storeManager = StoreManager()

    @AppStorage("useImperial") private var useImperial: Bool = false
    @AppStorage("useNightMode") private var useNightMode: Bool = false

    @AppStorage("calibPitch") private var calibPitch: Double = 0.0
    @AppStorage("calibRoll") private var calibRoll: Double = 0.0

    @AppStorage("isFirstLaunch") private var isFirstLaunch: Bool = true

    @State private var showCompass = false
    @State private var showSettings = false
    @State private var showWeatherDetail = false
    @State private var showWheelAdjust = false
    @State private var showHelp = false
    @State private var flashlightBrightness: Float = 1.0

    @State private var debugSimulateCompass = false
    @State private var simulatedHeading = 0.0
    @State private var hasRequestedInitialWeather = false
    @State private var hasLoadedStoreProducts = false

    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            (useNightMode ? Color.black : Color(white: 0.15))
                .ignoresSafeArea()

            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    if let location = locationManager.location {
                        Text(UnitFormatting.elevation(location.altitude, useImperial: useImperial))
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(useNightMode ? .red : .white)

                        Text("GPS: Accurate to \(max(0, Int(location.horizontalAccuracy)))m")
                            .font(.caption)
                            .foregroundColor(useNightMode ? .red.opacity(0.7) : .white)
                    } else {
                        Text("Getting Elevation...")
                            .font(.title2)
                            .foregroundColor(useNightMode ? .red : .white)
                    }

                    if let locationError = locationManager.errorMessage {
                        Text(locationError)
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.top)

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Weather")
                            .font(.headline)
                        Spacer()
                        Button(action: refreshWeather) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }

                    if weatherService.isLoading {
                        Text("Loading weather...")
                    } else if let error = weatherService.errorMessage, !error.isEmpty {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else if let weather = weatherService.weather,
                              let summary = WeatherHelper.process(weather, useImperial: useImperial) {
                        HStack {
                            Text("Now: \(UnitFormatting.temperature(summary.nowTemp, useImperial: useImperial))")
                                .font(.title3)
                            Spacer()
                            Text("Wind: \(UnitFormatting.speed(summary.windSpeed, useImperial: useImperial)) \(summary.windDirection)")
                        }

                        Text("Next 24h: \(UnitFormatting.temperature(summary.minTemp24h, useImperial: useImperial)) / \(UnitFormatting.temperature(summary.maxTemp24h, useImperial: useImperial))")
                            .font(.subheadline)

                        HStack {
                            Text("Precip: \(summary.precipDescription)")
                                .font(.caption)
                            if summary.precipTotal > 0.05 {
                                Text("(\(UnitFormatting.precipitation(summary.precipTotal, useImperial: useImperial)))")
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

                Toggle("Show Compass", isOn: $showCompass)
                    .padding()
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .foregroundColor(useNightMode ? .red : .white)
                    .tint(useNightMode ? .red : .teal)

                ZStack {
                    if showCompass {
                        if let heading = displayHeading {
                            VStack(spacing: 12) {
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
                            let pitch = -asin(max(-1, min(1, tiltY))) * 180 / .pi
                            let roll = asin(max(-1, min(1, tiltX))) * 180 / .pi

                            Text(String(format: "Pitch: %.1f°  Roll: %.1f°", pitch, roll))
                                .font(.title3)
                                .foregroundColor(useNightMode ? .red : .white)
                        }
                    }
                }
                .frame(maxHeight: .infinity)

                VStack {
                    Toggle(isOn: $flashlightManager.isFlashlightOn) {
                        Text("Flashlight")
                            .foregroundColor(useNightMode ? .red : .white)
                    }
                    .tint(useNightMode ? .red : .teal)
                    .onChange(of: flashlightManager.isFlashlightOn) { _, newValue in
                        flashlightManager.setFlashlight(on: newValue, brightness: flashlightBrightness)
                    }

                    if flashlightManager.isFlashlightOn {
                        Slider(value: $flashlightBrightness, in: 0.01...1.0)
                            .accentColor(useNightMode ? .red : .teal)
                            .onChange(of: flashlightBrightness) { _, newValue in
                                flashlightManager.setFlashlight(on: true, brightness: newValue)
                            }
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(10)

                HStack(spacing: 20) {
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
        .onReceive(locationManager.$location.compactMap { $0 }) { location in
            guard !hasRequestedInitialWeather else { return }
            hasRequestedInitialWeather = true
            weatherService.fetchWeather(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView(motionManager: motionManager, debugSimulateCompass: $debugSimulateCompass)
        }
        .sheet(isPresented: $showWeatherDetail) {
            if let weather = weatherService.weather,
               let summary = WeatherHelper.process(weather, useImperial: useImperial) {
                WeatherDetailView(summary: summary, useImperial: useImperial, useNightMode: useNightMode)
                    .presentationBackground(useNightMode ? .black : Color(white: 0.15))
            }
        }
        .fullScreenCover(isPresented: $showWheelAdjust) {
            WheelAdjustView(motionManager: motionManager)
        }
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                startLiveUpdates()
            case .inactive, .background:
                stopLiveUpdates()
            @unknown default:
                break
            }
        }
        .onAppear {
            flashlightManager.setFlashlight(on: false)

            if isFirstLaunch {
                showHelp = true
                isFirstLaunch = false
            }

            if scenePhase == .active {
                startLiveUpdates()
            }

            if !hasLoadedStoreProducts {
                hasLoadedStoreProducts = true
                Task {
                    await storeManager.loadProducts()
                }
            }
        }
        .onDisappear {
            stopLiveUpdates()
            flashlightManager.setFlashlight(on: false)
        }
    }

    private var displayHeading: Double? {
        if debugSimulateCompass {
            return simulatedHeading
        }

        guard let heading = locationManager.heading else {
            return nil
        }

        let bestHeading = heading.trueHeading >= 0 ? heading.trueHeading : heading.magneticHeading
        return bestHeading >= 0 ? bestHeading : nil
    }

    private func refreshWeather() {
        if let loc = locationManager.location {
            weatherService.fetchWeather(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude)
        } else {
            locationManager.requestLocation()
        }
    }

    private func startLiveUpdates() {
        locationManager.startUpdates()
        motionManager.startUpdates()
    }

    private func stopLiveUpdates() {
        locationManager.stopUpdates()
        motionManager.stopUpdates()
    }

    private func cardinalDirection(_ heading: Double) -> String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((heading + 22.5) / 45.0) & 7
        return directions[index]
    }

    private func calculateTilt() -> (Double, Double) {
        let rawX = motionManager.gravityX
        let rawY = motionManager.gravityY

        let finalX = rawX - calibRoll
        let finalY = rawY - calibPitch

        return (finalX, finalY)
    }
}

#Preview {
    ContentView()
}
