import Combine
import Foundation
import OTPCore
import XCTest

final class EpochClockTests: XCTestCase {
    func test_currentTime_isInjectedCurrentTime() {
        let sut = EpochClock(makeCurrentTime: { 1234 })

        XCTAssertEqual(sut.currentTime, 1234)
    }
}
