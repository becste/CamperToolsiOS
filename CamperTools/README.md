# CamperTools iOS 🚐

**CamperTools iOS** is a lightweight, ad-free utility app designed for RVers, campers, and van-lifers, ported from the original Android version to SwiftUI. It combines essential tools into a single, battery-friendly interface to help you park, level, and plan your stay.

## ✨ Features

*   **📏 Leveling Tool:** Precise 2-axis bubble level with visual guides. Calibrate it to your vehicle's unique floor or counter tilt.
*   **📐 Wheel Height Adjust:** Input your vehicle's dimensions to calculate the exact shim height needed for each wheel (**FL, FR, BL, BR**) to achieve a perfect level. Includes a **2S delayed recalculate** feature to average readings for maximum precision.
*   **📖 In-App Guide:** Comprehensive manual explaining all features, available on first startup or anytime via Settings.
*   **🧭 Compass:** Smooth, filtered compass heading.
*   **🌤️ Weather Forecast:**
    *   Instant current conditions.
    *   **Rolling 24-hour forecast** for temperature (min/max), wind gusts, and precipitation.
    *   Detailed "Extra Data" view with Sunrise/Sunset times, Sunshine duration, and Cloud cover.
    *   Powered by [Open-Meteo](https://open-meteo.com/).
*   **🔦 Flashlight:** Quick access to the camera LED with adjustable brightness and **Shake-to-Toggle** feature.
*   **🔴 Night Mode:** Preserves your night vision with a red-light interface and dimmed screen.
*   **📐 Auto-Calibration:** Easily zero out your level with a single tap in settings to account for camera bumps or uneven surfaces.

## 🛠️ Tech Stack

*   **Language:** Swift
*   **Framework:** SwiftUI
*   **Platform:** iOS 15.0+
*   **Architecture:** Combine-driven ObservableObjects (MVVM).
*   **APIs:**
    *   **Location:** CoreLocation for accurate weather and elevation.
    *   **Motion:** CoreMotion (CMMotionManager) for fused, stable orientation data.
    *   **Weather:** Open-Meteo API (No API key required).

## 🚀 Getting Started

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/becste/CamperToolsiOS.git
    ```
2.  **Open in Xcode:**
    Open the project folder or `CamperTools.xcodeproj`.
3.  **Configure Permissions:**
    Ensure `Info.plist` includes:
    - `NSLocationWhenInUseUsageDescription`
    - `NSCameraUsageDescription`
4.  **Build and Run:**
    Press `Cmd + R` to run on the Simulator or a physical iPhone.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 🔗 Related Projects

*   **Original Android Version:** [CamperTools Android](https://github.com/becste/CamperTools)
*   **Android App:** [Play Store Link](https://play.google.com/store/apps/details?id=com.campertools.app)

## 📄 License

This project is licensed under the **Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)**. 

---
*Weather data provided by [Open-Meteo.com](https://open-meteo.com/)*