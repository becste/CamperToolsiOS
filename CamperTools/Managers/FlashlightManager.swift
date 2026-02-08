import Foundation
import AVFoundation
import Combine

class FlashlightManager: ObservableObject {
    @Published var isFlashlightOn: Bool = false
    
    // Brightness 0.0 to 1.0
    func setFlashlight(on: Bool, brightness: Float = 1.0) {
        // Update state regardless of hardware availability (for Simulator testing)
        // But in real app, we might want to ensure hardware worked.
        // For now, let's update state first so UI reacts.
        isFlashlightOn = on
        
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            
            if on {
                // Ensure brightness is at least minimal if on
                let level = max(0.01, min(brightness, 1.0))
                try device.setTorchModeOn(level: level)
            } else {
                device.torchMode = .off
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Flashlight Error: \(error)")
            // Revert state if hardware failed?
            isFlashlightOn = false
        }
    }
    
    func toggle() {
        setFlashlight(on: !isFlashlightOn)
    }
}
