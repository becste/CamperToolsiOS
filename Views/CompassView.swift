import SwiftUI

struct CompassView: View {
    var heading: Double // 0-360
    var isNightMode: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let radius = min(width, height) / 2.0 * 0.8
            let centerX = width / 2.0
            let centerY = height / 2.0
            
            ZStack {
                // Outer Circle
                Circle()
                    .stroke(isNightMode ? Color.red : Color.white, lineWidth: 6)
                    .frame(width: radius * 2, height: radius * 2)
                    .position(x: centerX, y: centerY)
                
                // Rotating Content
                ZStack {
                    // North Triangle
                    Path { path in
                        path.move(to: CGPoint(x: centerX, y: centerY - radius))
                        path.addLine(to: CGPoint(x: centerX - 20, y: centerY))
                        path.addLine(to: CGPoint(x: centerX + 20, y: centerY))
                        path.closeSubpath()
                    }
                    .fill(Color.red)
                    
                    // South Triangle
                    Path { path in
                        path.move(to: CGPoint(x: centerX, y: centerY + radius))
                        path.addLine(to: CGPoint(x: centerX - 20, y: centerY))
                        path.addLine(to: CGPoint(x: centerX + 20, y: centerY))
                        path.closeSubpath()
                    }
                    .fill(isNightMode ? Color.red.opacity(0.5) : Color.white.opacity(0.5))
                    
                    // Text Labels
                    Group {
                        Text("N")
                            .position(x: centerX, y: centerY - radius - 30)
                        Text("S")
                            .position(x: centerX, y: centerY + radius + 40)
                        Text("E")
                            .position(x: centerX + radius + 30, y: centerY)
                        Text("W")
                            .position(x: centerX - radius - 30, y: centerY)
                    }
                    .foregroundColor(isNightMode ? .red : .white)
                    .font(.headline)
                }
                .rotationEffect(Angle(degrees: -heading))
                .animation(.linear, value: heading)
            }
        }
    }
}
