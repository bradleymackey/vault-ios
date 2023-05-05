import Combine
import Foundation
import OTPCore
import OTPFeed
import XCTest

final class CodeTimerControllerTests: XCTestCase {
    func test_timerUpdatedPublisher_initiallyPublishesForCreation() async throws {
        let (_, sut) = makeSUT(clock: 62, period: 30)

        let publisher = sut.timerUpdatedPublisher().collectFirst(1)

        let values = try await awaitPublisher(publisher, when: {
            // noop
        })
        XCTAssertEqual(values, [OTPTimerState(startTime: 60, endTime: 90)])
    }

    func test_timerUpdatedPublisher_publishesCounterInitialRanges() async throws {
        let (clock, sut) = makeSUT(clock: 32, period: 30)

        let publisher = sut.timerUpdatedPublisher().collectFirst(3)

        let values = try await awaitPublisher(publisher, when: {
            clock.send(time: 60)
            clock.finishTimer()
            clock.send(time: 90)
            clock.finishTimer()
        })
        XCTAssertEqual(values, [
            OTPTimerState(startTime: 30, endTime: 60),
            OTPTimerState(startTime: 60, endTime: 90),
            OTPTimerState(startTime: 90, endTime: 120),
        ])
    }

    // MARK: - Helpers

    private func makeSUT(
        clock clockTime: Double,
        period: Double
    ) -> (MockEpochClock, CodeTimerController<MockEpochClock>) {
        let clock = MockEpochClock(initialTime: clockTime)
        let sut = CodeTimerController(clock: clock, period: period)
        return (clock, sut)
    }
}
