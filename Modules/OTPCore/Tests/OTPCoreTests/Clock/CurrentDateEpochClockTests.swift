import Combine
import Foundation
import OTPCore
import XCTest

final class CurrentDateEpochClockTests: XCTestCase {
    func test_currentTime_isInjectedCurrentTime() {
        let sut = makeSUT(value: 1234)

        XCTAssertEqual(sut.currentTime, 1234)
    }

    func test_secondsPublisher_ticksWithCurrentTimeWhenRequested() throws {
        let sut = makeSUT(value: 1234)

        let publisher = sut.secondsPublisher()
            .collect(3)
            .first()

        let values = try awaitPublisher(publisher, timeout: 2) {
            sut.tick()
            sut.tick()
            sut.tick()
        }
        XCTAssertEqual(values, [1234, 1234, 1234])
    }

    func test_timerPublisher_completesAfterFirstPublish() throws {
        let sut = makeSUT(value: 1234)

        // The publisher should complete as-is, not timeout.
        try awaitPublisher(sut.timerPublisher(time: 0.1), timeout: 1) {
            // noop
        }
    }

    // MARK: - Helpers

    private func makeSUT(value: Double) -> CurrentDateEpochClock {
        let value = Date(timeIntervalSince1970: value)
        return CurrentDateEpochClock(currentDate: { value })
    }
}
