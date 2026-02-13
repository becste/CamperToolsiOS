import SwiftUI
import Combine

struct WheelAdjustView: View {
    @ObservedObject var motionManager: MotionManager
    
    @AppStorage("useImperial") private var useImperial: Bool = false
    @AppStorage("useNightMode") private var useNightMode: Bool = false
    
    @AppStorage("calibPitch") private var calibPitch: Double = 0.0
    @AppStorage("calibRoll") private var calibRoll: Double = 0.0
    
    @AppStorage("pref_wheelbase") private var wheelbase: Double = 0.0
    @AppStorage("pref_track_width") private var trackWidth: Double = 0.0
    
    @State private var wheelbaseStr: String = ""
    @State private var trackWidthStr: String = ""
    
    @Environment(\.dismiss) var dismiss
    
    @State private var currentTiltX: Double = 0.0
    @State private var currentTiltY: Double = 0.0
    
    @State private var isMeasuring = false
    @State private var countdown: Int = 0
    @State private var measurementTimer: Timer?
    
    // Measurement accumulators
    @State private var sumX: Double = 0.0
    @State private var sumY: Double = 0.0
    @State private var count: Int = 0
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ZStack {
                (useNightMode ? Color.black : Color(white: 0.15))
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 15) {
                        
                        // Inputs
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Vehicle Dimensions")
                                .font(.headline)
                                .foregroundColor(useNightMode ? .red : .white)
                            
                            HStack(spacing: 15) {
                                dimensionInput(label: "Wheelbase (\(useImperial ? "in" : "cm"))", text: $wheelbaseStr)
                                dimensionInput(label: "Track Width (\(useImperial ? "in" : "cm"))", text: $trackWidthStr)
                            }
                        }
                        .padding(12)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Results Grid
                        VStack(spacing: 10) {
                            let shims = calculateShims()
                            
                            Text("FRONT (Phone Top)")
                                .font(.caption.bold())
                                .foregroundColor(useNightMode ? .red : .white)
                            
                            HStack(spacing: 30) {
                                shimView(label: "FL", value: shims.fl)
                                shimView(label: "FR", value: shims.fr)
                            }
                            
                            // Visual vehicle representation
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(useNightMode ? Color.red : Color.white.opacity(0.3), lineWidth: 2)
                                    .frame(width: 80, height: 120)
                                
                                VStack {
                                    Image(systemName: "arrow.up")
                                        .foregroundColor(useNightMode ? .red : .white.opacity(0.5))
                                    Text("VEHICLE\nFRONT")
                                        .font(.system(size: 8, weight: .bold))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(useNightMode ? .red : .white.opacity(0.5))
                                }
                            }
                            .padding(.vertical, 5)
                            
                            HStack(spacing: 30) {
                                shimView(label: "BL", value: shims.bl)
                                shimView(label: "BR", value: shims.br)
                            }
                            
                            Text("REAR")
                                .font(.caption.bold())
                                .foregroundColor(useNightMode ? .red : .white)
                        }
                        .padding(12)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Recalculate Button
                        Button(action: startMeasurement) {
                            HStack {
                                if isMeasuring {
                                    ProgressView()
                                        .tint(useNightMode ? .red : .white)
                                        .padding(.trailing, 10)
                                    Text("Measuring... (\(countdown))")
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                    Text("2S delayed recalculate")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(isMeasuring ? Color.gray.opacity(0.3) : Color.secondary.opacity(0.1))
                            .foregroundColor(useNightMode ? .red : .teal)
                            .cornerRadius(10)
                        }
                        .disabled(isMeasuring)
                        
                        Button(action: { dismiss() }) {
                            Text("Close")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.secondary.opacity(0.2))
                                .foregroundColor(useNightMode ? .red : .teal)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                }
            }
            .navigationTitle("Height Adjust")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Save") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .foregroundColor(useNightMode ? .red : .teal)
                }
            }
            .toolbarBackground(useNightMode ? Color.black : Color(white: 0.15), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .tint(useNightMode ? .red : .teal)
            .onReceive(timer) { _ in
                if isMeasuring {
                    sumX += motionManager.gravityX
                    sumY += motionManager.gravityY
                    count += 1
                } else {
                    // Update current live tilt for calculation if not locked
                    currentTiltX = motionManager.gravityX - calibRoll
                    currentTiltY = motionManager.gravityY - calibPitch
                }
            }
            .onChange(of: wheelbaseStr) { newValue in
                if let d = Double(newValue) { wheelbase = d }
            }
            .onChange(of: trackWidthStr) { newValue in
                if let d = Double(newValue) { trackWidth = d }
            }
        }
        .onAppear {
            wheelbaseStr = wheelbase == 0 ? "" : String(format: "%.1f", wheelbase)
            trackWidthStr = trackWidth == 0 ? "" : String(format: "%.1f", trackWidth)
            
            currentTiltX = motionManager.gravityX - calibRoll
            currentTiltY = motionManager.gravityY - calibPitch
        }
        .onDisappear {
            measurementTimer?.invalidate()
            measurementTimer = nil
        }
    }
    
    private func dimensionInput(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption)
                .foregroundColor(useNightMode ? .red : .white)
            
            TextField("0.0", text: text)
                .keyboardType(.decimalPad)
                .padding(10)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(8)
                .foregroundColor(useNightMode ? .red : .white)
        }
    }
    
    private func shimView(label: String, value: Double) -> some View {
        VStack(spacing: 5) {
            Text(label)
                .font(.headline)
                .foregroundColor(useNightMode ? .red : .white)
            
            Text(UnitFormatting.shimHeight(value, useImperial: useImperial))
                .font(.title2.bold())
                .foregroundColor(useNightMode ? .red : .teal)
        }
        .frame(width: 80)
    }
    
    private func startMeasurement() {
        isMeasuring = true
        sumX = 0
        sumY = 0
        count = 0
        countdown = 20 // 2 seconds at 0.1s intervals

        measurementTimer?.invalidate()
        measurementTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            self.countdown -= 1
            if self.countdown <= 0 {
                timer.invalidate()
                self.measurementTimer = nil
                self.finishMeasurement()
            }
        }
    }
    
    private func finishMeasurement() {
        if count > 0 {
            let avgX = sumX / Double(count)
            let avgY = sumY / Double(count)
            
            currentTiltX = avgX - calibRoll
            currentTiltY = avgY - calibPitch
        }
        isMeasuring = false
    }
    
    private func calculateShims() -> (fl: Double, fr: Double, bl: Double, br: Double) {
        ShimCalculator.calculate(
            tiltX: currentTiltX,
            tiltY: currentTiltY,
            wheelbase: wheelbase,
            trackWidth: trackWidth
        )
    }
}
