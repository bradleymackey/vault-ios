import Combine
import Foundation
import OTPCore
import OTPFeed
import XCTest

final class CodeTimerViewModelTests: XCTestCase {
    func test_timerUpdatedPublisher_initiallyPublishesForCreation() async throws {
        let clock = MockEpochClock(initialTime: 62)
        let sut = CodeTimerViewModel(clock: clock, period: 30)

        let publisher = sut.timerUpdatedPublisher().collectFirst(1)

        let values = try await awaitPublisher(publisher, when: {
            // noop
        })
        XCTAssertEqual(values, [OTPTimerState(startTime: 60, endTime: 90)])
    }

    func test_timerUpdatedPublisher_publishesCounterInitialRanges() async throws {
        let clock = MockEpochClock(initialTime: 32)
        let sut = CodeTimerViewModel(clock: clock, period: 30)

        let publisher = sut.timerUpdatedPublisher().collectFirst(3)

        let values = try await awaitPublisher(publisher, when: {
            clock.send(time: 60)
            clock.finishTimer(currentTime: 60)
            clock.send(time: 90)
            clock.finishTimer(currentTime: 90)
        })
        XCTAssertEqual(values, [
            OTPTimerState(startTime: 30, endTime: 60),
            OTPTimerState(startTime: 60, endTime: 90),
            OTPTimerState(startTime: 90, endTime: 120),
        ])
    }
}
