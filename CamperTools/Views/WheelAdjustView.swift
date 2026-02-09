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
    
    @Environment(\.dismiss) var dismiss
    
    @State private var currentTiltX: Double = 0.0
    @State private var currentTiltY: Double = 0.0
    
    @State private var isMeasuring = false
    @State private var countdown: Int = 0
    
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
                
                VStack(spacing: 15) {
                    
                    // Inputs
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Vehicle Dimensions")
                            .font(.headline)
                            .foregroundColor(useNightMode ? .red : .white)
                        
                        HStack(spacing: 15) {
                            dimensionInput(label: "Wheelbase (\(useImperial ? "in" : "cm"))", value: $wheelbase)
                            dimensionInput(label: "Track Width (\(useImperial ? "in" : "cm"))", value: $trackWidth)
                        }
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
                        .background(isMeasuring ? Color.gray.opacity(0.3) : (useNightMode ? Color.red.opacity(0.2) : Color.teal.opacity(0.2)))
                        .foregroundColor(useNightMode ? .red : .teal)
                        .cornerRadius(10)
                    }
                    .disabled(isMeasuring)
                    
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
                                Text("FRONT")
                                    .font(.system(size: 8, weight: .bold))
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
                    
                    Spacer()
                    
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
            .navigationTitle("Height Adjust")
            .navigationBarTitleDisplayMode(.inline)
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
        }
        .onAppear {
            currentTiltX = motionManager.gravityX - calibRoll
            currentTiltY = motionManager.gravityY - calibPitch
            
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = useNightMode ? .black : UIColor(white: 0.15, alpha: 1.0)
            appearance.titleTextAttributes = [.foregroundColor: useNightMode ? UIColor.red : UIColor.white]
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    private func dimensionInput(label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption)
                .foregroundColor(useNightMode ? .red : .white)
            
            TextField("0.0", value: value, format: .number)
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
            
            Text(formatShim(value))
                .font(.title2.bold())
                .foregroundColor(useNightMode ? .red : .teal)
        }
        .frame(width: 80)
    }
    
    private func formatShim(_ val: Double) -> String {
        if useImperial {
            return String(format: "%.1f\"", val)
        } else {
            return String(format: "%.1f cm", val)
        }
    }
    
    private func startMeasurement() {
        isMeasuring = true
        sumX = 0
        sumY = 0
        count = 0
        countdown = 20 // 2 seconds at 0.1s intervals
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            countdown -= 1
            if countdown <= 0 {
                timer.invalidate()
                finishMeasurement()
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
        // Invert tilt values to match Android logic: 
        // iOS gravity.y is negative when top is tilted UP.
        // Android adjustedY is positive when top is tilted UP.
        let adjX = -max(-1, min(1, currentTiltX))
        let adjY = -max(-1, min(1, currentTiltY))
        
        // Height Calculation (from Android logic)
        let hFront = (wheelbase / 2.0) * adjY
        let hRear = -(wheelbase / 2.0) * adjY
        
        let hRight = (trackWidth / 2.0) * adjX
        let hLeft = -(trackWidth / 2.0) * adjX
        
        // Corners
        let hFL = hFront + hLeft
        let hFR = hFront + hRight
        let hBL = hRear + hLeft
        let hBR = hRear + hRight
        
        // Shim = difference from MAX
        let maxH = max(max(hFL, hFR), max(hBL, hBR))
        
        return (
            fl: maxH - hFL,
            fr: maxH - hFR,
            bl: maxH - hBL,
            br: maxH - hBR
        )
    }
}
