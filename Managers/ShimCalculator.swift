import Foundation

enum ShimCalculator {
    static func calculate(
        tiltX: Double,
        tiltY: Double,
        wheelbase: Double,
        trackWidth: Double
    ) -> (fl: Double, fr: Double, bl: Double, br: Double) {
        let adjX = -max(-1, min(1, tiltX))
        let adjY = -max(-1, min(1, tiltY))

        let hFront = (wheelbase / 2.0) * adjY
        let hRear = -(wheelbase / 2.0) * adjY

        let hRight = (trackWidth / 2.0) * adjX
        let hLeft = -(trackWidth / 2.0) * adjX

        let hFL = hFront + hLeft
        let hFR = hFront + hRight
        let hBL = hRear + hLeft
        let hBR = hRear + hRight

        let maxH = max(max(hFL, hFR), max(hBL, hBR))

        return (
            fl: maxH - hFL,
            fr: maxH - hFR,
            bl: maxH - hBL,
            br: maxH - hBR
        )
    }
}
