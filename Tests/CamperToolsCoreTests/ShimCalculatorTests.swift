#if canImport(XCTest) && canImport(CamperToolsCore)
import XCTest
@testable import CamperToolsCore

final class ShimCalculatorTests: XCTestCase {
    func testLevelVehicleRequiresNoShim() {
        let shims = ShimCalculator.calculate(tiltX: 0, tiltY: 0, wheelbase: 120, trackWidth: 70)

        XCTAssertEqual(shims.fl, 0, accuracy: 0.0001)
        XCTAssertEqual(shims.fr, 0, accuracy: 0.0001)
        XCTAssertEqual(shims.bl, 0, accuracy: 0.0001)
        XCTAssertEqual(shims.br, 0, accuracy: 0.0001)
    }

    func testRightSideLowProducesRightSideShim() {
        let shims = ShimCalculator.calculate(tiltX: 1, tiltY: 0, wheelbase: 120, trackWidth: 100)

        XCTAssertEqual(shims.fl, 0, accuracy: 0.0001)
        XCTAssertEqual(shims.fr, 100, accuracy: 0.0001)
        XCTAssertEqual(shims.bl, 0, accuracy: 0.0001)
        XCTAssertEqual(shims.br, 100, accuracy: 0.0001)
    }

    func testAtLeastOneCornerAlwaysZero() {
        let shims = ShimCalculator.calculate(tiltX: 0.2, tiltY: -0.1, wheelbase: 110, trackWidth: 60)
        let values = [shims.fl, shims.fr, shims.bl, shims.br]

        XCTAssertGreaterThanOrEqual(values.min() ?? -1, 0)
        XCTAssertEqual(values.min() ?? -1, 0, accuracy: 0.0001)
    }
}
#endif
