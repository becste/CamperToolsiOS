import Foundation
import CoreMotion
import Combine

class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    
    @Published var gravityX: Double = 0.0
    @Published var gravityY: Double = 0.0
    
    func startUpdates() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (data, error) in
                guard let data = data else { return }
                // In iOS, gravity.x/y are in g-force units (-1 to 1)
                self?.gravityX = data.gravity.x
                self?.gravityY = data.gravity.y
            }
        }
    }
    
    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
}
