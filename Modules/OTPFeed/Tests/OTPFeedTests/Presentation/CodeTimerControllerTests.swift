import Combine
import Foundation
import OTPCore
import OTPFeed
import XCTest

final class CodeTimerControllerTests: XCTestCase {
    func test_timerUpdatedPublisher_publishesInitialValueImmediately() async throws {
        let (_, _, sut) = makeSUT(clock: 62, period: 30)

        let publisher = sut.timerUpdatedPublisher().collectFirst(1)

        let values = try await awaitPublisher(publisher, when: {
            // noop
        })
        XCTAssertEqual(values, [OTPTimerState(startTime: 60, endTime: 90)])
    }

    func test_timerUpdatedPublisher_publishesStateForCurrentTimeOnTimerFinish() async throws {
        let (clock, timer, sut) = makeSUT(clock: 32, period: 30)

        let publisher = sut.timerUpdatedPublisher().collectFirst(3)

        let values = try await awaitPublisher(publisher, when: {
            clock.makeCurrentTime = { 60 }
            timer.finishTimer()
            clock.makeCurrentTime = { 90 }
            timer.finishTimer()
        })
        XCTAssertEqual(values, [
            OTPTimerState(startTime: 30, endTime: 60), // initial time
            OTPTimerState(startTime: 60, endTime: 90),
            OTPTimerState(startTime: 90, endTime: 120),
        ])
    }

    func test_recalculate_forcesPublishOfCurrentTimerState() async throws {
        let (clock, _, sut) = makeSUT(clock: 32, period: 30)

        let publisher = sut.timerUpdatedPublisher().collectFirst(3)

        let values = try await awaitPublisher(publisher, when: {
            clock.makeCurrentTime = { 301 }
            sut.recalculate()
            clock.makeCurrentTime = { 330 }
            sut.recalculate()
        })
        XCTAssertEqual(values, [
            OTPTimerState(startTime: 30, endTime: 60), // initial time
            OTPTimerState(startTime: 300, endTime: 330),
            OTPTimerState(startTime: 330, endTime: 360),
        ])
    }

    func test_recalculate_publishesDuplicateStatesIfRecalculatingInSamePeriod() async throws {
        let (_, _, sut) = makeSUT(clock: 32, period: 30)

        let publisher = sut.timerUpdatedPublisher().collectFirst(3)

        let values = try await awaitPublisher(publisher, when: {
            sut.recalculate()
            sut.recalculate()
        })
        XCTAssertEqual(values, [
            OTPTimerState(startTime: 30, endTime: 60), // initial time
            OTPTimerState(startTime: 30, endTime: 60),
            OTPTimerState(startTime: 30, endTime: 60),
        ])
    }

    // MARK: - Helpers

    private func makeSUT(
        clock clockTime: Double,
        period: UInt64,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (EpochClock, MockIntervalTimer, CodeTimerController) {
        let timer = MockIntervalTimer()
        let clock = EpochClock(makeCurrentTime: { clockTime })
        let sut = CodeTimerController(timer: timer, period: period, clock: clock)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (clock, timer, sut)
    }
}
