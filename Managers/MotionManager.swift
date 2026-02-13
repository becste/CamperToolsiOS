import Foundation
import CoreMotion
import Combine

@MainActor
final class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private(set) var isUpdating = false

    @Published var gravityX: Double = 0.0
    @Published var gravityY: Double = 0.0

    func startUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        guard !isUpdating else { return }

        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }
            self?.gravityX = data.gravity.x
            self?.gravityY = data.gravity.y
        }

        isUpdating = true
    }

    func stopUpdates() {
        guard isUpdating else { return }
        motionManager.stopDeviceMotionUpdates()
        isUpdating = false
    }
}
