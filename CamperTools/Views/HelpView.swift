import SwiftUI

struct HelpView: View {
    @AppStorage("useNightMode") private var useNightMode: Bool = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                (useNightMode ? Color.black : Color(white: 0.15))
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        helpSection(
                            title: "Main Screen",
                            text: "Check your Elevation and GPS status. View current Temperature, Wind, and Precipitation. Tap 'More data' for a 3-day forecast. Use the switch to toggle between Level and Compass views. Check Pitch & Roll on the level, or tap 'Height Adjust' for wheel shim calculations. Shake your device to toggle the Flashlight."
                        )
                        
                        helpSection(
                            title: "Weather Details",
                            text: "Tap 'More data' for a 3-day forecast, sunrise/sunset times, and cloud cover info."
                        )
                        
                        helpSection(
                            title: "Height Adjust",
                            text: "Tap 'Height Adjust' next to the level. Enter your vehicle's Wheelbase and Track Width. Tap '2S delayed recalculate' to get a fix on the current readings and a height adjustment recommendation."
                        )
                        
                        helpSection(
                            title: "Settings",
                            text: "In the Settings menu, you can calibrate the level (manually or auto), toggle 'Night Mode' for a red-light interface, and switch between Metric and Imperial units."
                        )
                        
                        VStack(spacing: 12) {
                            Text("This guide is available anytime via the Help button in the Settings menu.")
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                .foregroundColor(useNightMode ? .red : .white.opacity(0.8))
                                .frame(maxWidth: .infinity)
                            
                            Button(action: { dismiss() }) {
                                Text("Close Guide")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(useNightMode ? Color.red.opacity(0.2) : Color.teal.opacity(0.2))
                                    .foregroundColor(useNightMode ? .red : .teal)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.top, 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("CamperTools Guide v1.3")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(useNightMode ? .red : .secondary)
                    }
                }
            }
        }
        .onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = useNightMode ? .black : UIColor(white: 0.15, alpha: 1.0)
            appearance.titleTextAttributes = [.foregroundColor: useNightMode ? UIColor.red : UIColor.white]
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    private func helpSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(useNightMode ? .red : .white)
            
            Text(text)
                .font(.body)
                .foregroundColor(useNightMode ? .red.opacity(0.9) : .white.opacity(0.9))
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    HelpView()
}
