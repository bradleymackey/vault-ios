import Combine
import Foundation
import OTPCore
import XCTest

final class CurrentDateEpochClockTests: XCTestCase {
    func test_currentTime_isInjectedCurrentTime() {
        let sut = makeSUT(value: 1234.14)

        XCTAssertEqual(sut.currentTime, 1234)
    }

    func test_secondsPublisher_isInjectedCurrentTime() throws {
        let sut = makeSUT(value: 1234.14)

        let publisher = sut.secondsPublisher()
            .collect(2)
            .first()

        let values = try awaitPublisher(publisher, timeout: 2)
        XCTAssertEqual(values, [1234, 1234])
    }

    // MARK: - Helpers

    private func makeSUT(value: Double) -> CurrentDateEpochClock {
        let value = Date(timeIntervalSince1970: value)
        return CurrentDateEpochClock(currentDate: { value })
    }
}
