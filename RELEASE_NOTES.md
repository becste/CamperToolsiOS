# Release Notes - CamperTools iOS

## v1.8
*   **Consolidated Project Structure**: Cleaned up duplicate files and moved the primary source code to the root directory for better maintainability.
*   **App Store Optimization**: 
    *   Fixed App Icon mapping to ensure it appears correctly in App Store Connect.
    *   Resolved validation issues related to bundled executables and dSYMs.
*   **UI/UX Improvements**:
    *   **Height Adjust**: Added a ScrollView and "Save" button to the keyboard toolbar to prevent input fields from being obscured.
    *   **Opaque Overlays**: Switched Settings and Height Adjust screens to `fullScreenCover` to prevent background content from bleeding through when the keyboard is active.
    *   **Weather Details**: Fixed line-breaking issues for wind gusts in the 3-day forecast.
    *   **Visual Polish**: Updated text colors (GPS accuracy and Level Calibration) for better readability in standard mode.
*   **Bug Fixes**: 
    *   Improved stability of the IAP donation process and state management.
    *   Fixed a bug where the flashlight toggle would remain "on" in the UI after an app restart even if the light was off.
    *   Improved the editing experience in Height Adjust by allowing full deletion of input values.
