import Combine
import Foundation
import OTPCore
import XCTest

final class EpochClockTests: XCTestCase {
    func test_currentTime_isInjectedCurrentTime() {
        let sut = makeSUT(value: 1234)

        XCTAssertEqual(sut.currentTime, 1234)
    }

    // MARK: - Helpers

    private func makeSUT(value: Double) -> EpochClock {
        EpochClock(makeCurrentTime: { value })
    }
}
