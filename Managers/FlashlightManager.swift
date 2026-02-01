import Foundation
import AVFoundation
import Combine

class FlashlightManager: ObservableObject {
    @Published var isFlashlightOn: Bool = false
    
    // Brightness 0.0 to 1.0
    func setFlashlight(on: Bool, brightness: Float = 1.0) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            
            if on {
                // Ensure brightness is at least minimal if on
                let level = max(0.01, min(brightness, 1.0))
                try device.setTorchModeOn(level: level)
                isFlashlightOn = true
            } else {
                device.torchMode = .off
                isFlashlightOn = false
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Flashlight Error: \(error)")
        }
    }
    
    func toggle() {
        setFlashlight(on: !isFlashlightOn)
    }
}
