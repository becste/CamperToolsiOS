import SwiftUI

struct LevelView: View {
    var tiltX: Double // -1 to 1
    var tiltY: Double // -1 to 1
    var isNightMode: Bool
    
    // Hyperbolic gain constants
    private let HYPERBOLIC_GAIN: Double = 2.0
    private let HYPERBOLIC_NORMALIZER: Double = tanh(2.0)
    
    private func hyperbolicScale(_ value: Double) -> Double {
        return tanh(HYPERBOLIC_GAIN * value) / HYPERBOLIC_NORMALIZER
    }

    var body: some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height
            
            // Colors
            let primaryColor = isNightMode ? Color.red : Color.teal
            let secondaryColor = isNightMode ? Color.red : Color.white
            
            // Paints
            let bubbleStyle = primaryColor.opacity(0.8)
            let lineStyle = secondaryColor
            let centerLineStyle = secondaryColor.opacity(0.8)
            
            // Clamped Values
            let clampedX = max(-1, min(1, tiltX))
            let clampedY = max(-1, min(1, tiltY))
            let displayX = hyperbolicScale(clampedX)
            let displayY = hyperbolicScale(clampedY)
            
            // ---- CIRCULAR LEVEL (upper-leftish) ----
            let circleCx = width * 0.30
            let circleCy = height * 0.40
            let circleRadius = min(width, height) * 0.22
            let circleBubbleRadius = circleRadius / 5.0
            
            // Outer circle
            context.stroke(
                Path(ellipseIn: CGRect(x: circleCx - circleRadius, y: circleCy - circleRadius, width: circleRadius * 2, height: circleRadius * 2)),
                with: .color(secondaryColor),
                lineWidth: 2
            )
            
            // Concentric guides
            for i in 1...3 {
                let r = circleRadius * (Double(i) / 4.0)
                context.stroke(
                    Path(ellipseIn: CGRect(x: circleCx - r, y: circleCy - r, width: r * 2, height: r * 2)),
                    with: .color(secondaryColor.opacity(0.5)),
                    lineWidth: 1
                )
            }
            
            // Crosshair
            var crosshair = Path()
            crosshair.move(to: CGPoint(x: circleCx - circleRadius, y: circleCy))
            crosshair.addLine(to: CGPoint(x: circleCx + circleRadius, y: circleCy))
            crosshair.move(to: CGPoint(x: circleCx, y: circleCy - circleRadius))
            crosshair.addLine(to: CGPoint(x: circleCx, y: circleCy + circleRadius))
            context.stroke(crosshair, with: .color(secondaryColor), lineWidth: 2)
            
            // Bubble (moves opposite to tilt?)
            // Android:
            // float circleBubbleCx = circleCx + displayX * circleMaxOffset;
            // float circleBubbleCy = circleCy - displayY * circleMaxOffset;
            // Note: In Android LevelView.java, displayY is subtracted. Android Y is down?
            // Wait, Android Canvas Y is down (0 at top).
            // If phone tilts UP (top goes back), gravity Y is positive?
            // Let's verify tilt mapping later. For now assume displayX/Y match visual displacement.
            
            let circleMaxOffset = circleRadius - circleBubbleRadius
            let circleBubbleCx = circleCx + displayX * circleMaxOffset
            let circleBubbleCy = circleCy - displayY * circleMaxOffset
            
            context.fill(
                Path(ellipseIn: CGRect(x: circleBubbleCx - circleBubbleRadius, y: circleBubbleCy - circleBubbleRadius, width: circleBubbleRadius * 2, height: circleBubbleRadius * 2)),
                with: .color(primaryColor.opacity(0.8))
            )
            
            // ---- VERTICAL BAR LEVEL ----
            let vBarHeight = circleRadius * 2.0
            let vBarWidth = vBarHeight * 0.25
            let vBarCenterX = width * 0.75
            let vBarCenterY = circleCy
            
            let vBarRect = CGRect(x: vBarCenterX - vBarWidth/2, y: vBarCenterY - vBarHeight/2, width: vBarWidth, height: vBarHeight)
            let vBarRadius = vBarWidth / 2.0
            
            context.stroke(
                Path(roundedRect: vBarRect, cornerRadius: vBarRadius),
                with: .color(secondaryColor),
                lineWidth: 2
            )
            
            // Center Line
            var vCenterLine = Path()
            vCenterLine.move(to: CGPoint(x: vBarRect.minX, y: vBarCenterY))
            vCenterLine.addLine(to: CGPoint(x: vBarRect.maxX, y: vBarCenterY))
            context.stroke(vCenterLine, with: .color(secondaryColor), lineWidth: 2)
            
            // Guides
            for i in 1...2 {
                let offset = (vBarHeight / 2.0) * (Double(i) / 3.0)
                var guide = Path()
                guide.move(to: CGPoint(x: vBarRect.minX, y: vBarCenterY - offset))
                guide.addLine(to: CGPoint(x: vBarRect.maxX, y: vBarCenterY - offset))
                guide.move(to: CGPoint(x: vBarRect.minX, y: vBarCenterY + offset))
                guide.addLine(to: CGPoint(x: vBarRect.maxX, y: vBarCenterY + offset))
                context.stroke(guide, with: .color(secondaryColor.opacity(0.5)), lineWidth: 1)
            }
            
            let vBarBubbleRadius = vBarWidth / 2.5
            let vBarMaxOffset = (vBarHeight / 2.0) - vBarBubbleRadius - 6
            let vBarBubbleCy = vBarCenterY - displayY * vBarMaxOffset
            
            context.fill(
                Path(ellipseIn: CGRect(x: vBarCenterX - vBarBubbleRadius, y: vBarBubbleCy - vBarBubbleRadius, width: vBarBubbleRadius * 2, height: vBarBubbleRadius * 2)),
                with: .color(primaryColor.opacity(0.8))
            )
            
            // ---- HORIZONTAL BAR LEVEL ----
            let hBarWidth = width * 0.8
            let hBarHeight = height * 0.10
            let hBarCenterX = width / 2.0
            let hBarCenterY = height * 0.80
            
            let hBarRect = CGRect(x: hBarCenterX - hBarWidth/2, y: hBarCenterY - hBarHeight/2, width: hBarWidth, height: hBarHeight)
            let hBarRadius = hBarHeight / 2.0
            
            context.stroke(
                Path(roundedRect: hBarRect, cornerRadius: hBarRadius),
                with: .color(secondaryColor),
                lineWidth: 2
            )
            
            // Center Line
            var hCenterLine = Path()
            hCenterLine.move(to: CGPoint(x: hBarCenterX, y: hBarRect.minY))
            hCenterLine.addLine(to: CGPoint(x: hBarCenterX, y: hBarRect.maxY))
            context.stroke(hCenterLine, with: .color(secondaryColor), lineWidth: 2)
            
            // Guides
            for i in 1...4 {
                let offset = (hBarWidth / 2.0) * (Double(i) / 5.0)
                var guide = Path()
                guide.move(to: CGPoint(x: hBarCenterX - offset, y: hBarRect.minY))
                guide.addLine(to: CGPoint(x: hBarCenterX - offset, y: hBarRect.maxY))
                guide.move(to: CGPoint(x: hBarCenterX + offset, y: hBarRect.minY))
                guide.addLine(to: CGPoint(x: hBarCenterX + offset, y: hBarRect.maxY))
                context.stroke(guide, with: .color(secondaryColor.opacity(0.5)), lineWidth: 1)
            }
            
            let hBarBubbleRadius = hBarHeight / 2.5
            let hBarMaxOffset = (hBarWidth / 2.0) - hBarBubbleRadius - 8
            let hBarBubbleCx = hBarCenterX + displayX * hBarMaxOffset
            
            context.fill(
                Path(ellipseIn: CGRect(x: hBarBubbleCx - hBarBubbleRadius, y: hBarCenterY - hBarBubbleRadius, width: hBarBubbleRadius * 2, height: hBarBubbleRadius * 2)),
                with: .color(primaryColor.opacity(0.8))
            )
            
        }
    }
}
