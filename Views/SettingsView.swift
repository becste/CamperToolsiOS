import SwiftUI

struct SettingsView: View {
    @ObservedObject var motionManager: MotionManager
    @Binding var debugSimulateCompass: Bool // Simulator only

    @AppStorage("calibPitch") private var calibPitch: Double = 0.0
    @AppStorage("calibRoll") private var calibRoll: Double = 0.0

    @AppStorage("useImperial") private var useImperial: Bool = false
    @AppStorage("useNightMode") private var useNightMode: Bool = false
    @Environment(\.dismiss) var dismiss

    @State private var showHelp = false

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
                (useNightMode ? Color.black : Color(white: 0.15))
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 25) {

                        VStack(alignment: .leading, spacing: 15) {
                            Text("Level Calibration")
                                .font(.headline)
                                .foregroundColor(useNightMode ? .red : .white)

                            Text("Adjust the offsets manually (in degrees) or use Auto Calibrate to zero-out the current tilt.")
                                .font(.caption)
                                .foregroundColor(useNightMode ? .red.opacity(0.8) : .white)

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
            .toolbarBackground(useNightMode ? Color.black : Color(white: 0.15), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .tint(useNightMode ? .red : .teal)
        }
    }

    private func calibrate() {
        calibPitch = motionManager.gravityY
        calibRoll = motionManager.gravityX
    }

    private func reset() {
        calibPitch = 0.0
        calibRoll = 0.0
    }
}
