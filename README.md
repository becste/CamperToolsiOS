# CamperTools iOS

A comprehensive utility app for campers and outdoor enthusiasts, ported from Android to iOS using SwiftUI.

## Features

- **Spirit Level**: Visual 2D spirit level (circular and bar) to help level your camper or RV.
- **Compass**: Magnetic compass with heading display (Device required).
- **Altimeter**: Real-time elevation using GPS.
- **Weather**: Current local weather, wind speed/direction, and forecasts via Open-Meteo.
- **Flashlight**: Quick access toggle with adjustable brightness and "Shake to Toggle" feature.
- **Sun & Cloud Details**: Sunrise, sunset, sunshine duration, cloud cover, and max wind gusts.
- **Night Mode**: Red-tinted UI to preserve night vision.
- **Customizable**: Imperial/Metric units, calibration offset (bump height), and more.

## Requirements

- iOS 15.0+
- Xcode 13.0+
- iPhone (GPS and Magnetometer required for full functionality)

## Setup

1. Clone the repository.
2. Open `CamperTools.xcodeproj` (or the folder) in Xcode.
3. Ensure the project target has the necessary permissions in `Info.plist`:
   - `Privacy - Location When In Use Usage Description`
   - `Privacy - Camera Usage Description`
4. Run on a physical device for full sensor support (Compass, Flashlight).

## Simulator Tips

- **Location**: Use `Features > Location` in the Simulator menu to simulate GPS coordinates.
- **Compass**: A debug slider appears in the Simulator to manually rotate the compass UI.
- **Flashlight**: "Shake to Toggle" can be tested via `Device > Shake`.

## Credits

- Weather data provided by [Open-Meteo](https://open-meteo.com/).
- Android original concept by [CamperTools](https://play.google.com/store/apps/details?id=com.campertools.app).
