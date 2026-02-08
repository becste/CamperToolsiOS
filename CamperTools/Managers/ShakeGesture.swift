import SwiftUI

// A View that can detect shake gestures by becoming the first responder
struct ShakeDetector: UIViewRepresentable {
    let onShake: () -> Void
    
    func makeUIView(context: Context) -> ShakeView {
        let view = ShakeView()
        view.onShake = onShake
        return view
    }
    
    func updateUIView(_ uiView: ShakeView, context: Context) {}
    
    class ShakeView: UIView {
        var onShake: (() -> Void)?
        
        override func didMoveToWindow() {
            super.didMoveToWindow()
            becomeFirstResponder()
        }
        
        override var canBecomeFirstResponder: Bool { true }
        
        override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
            if motion == .motionShake {
                onShake?()
            }
            super.motionEnded(motion, with: event)
        }
    }
}

// Extension to make it easy to add to any view
extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.background(ShakeDetector(onShake: action))
    }
}