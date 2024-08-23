import Combine
import Foundation
import TestHelpers
import VaultCore
import VaultFeed
import XCTest

final class OTPCodeTimerUpdaterImplTests: XCTestCase {
    @MainActor
    func test_timerUpdatedPublisher_publishesInitialValueImmediately() async throws {
        let (_, _, sut) = makeSUT(clock: 62, period: 30)

        let publisher = sut.timerUpdatedPublisher().collectFirst(1)

        let values = try await awaitPublisher(publisher, when: {
            // noop
        })
        XCTAssertEqual(values, [OTPCodeTimerState(startTime: 60, endTime: 90)])
    }

    @MainActor
    func test_timerUpdatedPublisher_publishesStateForCurrentTimeOnTimerFinish() async throws {
        let (clock, timer, sut) = makeSUT(clock: 32, period: 30)

        let publisher = sut.timerUpdatedPublisher().collectFirst(3)

        let values = try await awaitPublisher(publisher, when: {
            clock.currentTimeProvider.modify { $0 = 60 }
            timer.finishTimer()
            clock.currentTimeProvider.modify { $0 = 90 }
            timer.finishTimer()
        })
        XCTAssertEqual(values, [
            OTPCodeTimerState(startTime: 30, endTime: 60), // initial time
            OTPCodeTimerState(startTime: 60, endTime: 90),
            OTPCodeTimerState(startTime: 90, endTime: 120),
        ])
    }

    @MainActor
    func test_recalculate_forcesPublishOfCurrentTimerState() async throws {
        let (clock, _, sut) = makeSUT(clock: 32, period: 30)

        let publisher = sut.timerUpdatedPublisher().collectFirst(3)

        let values = try await awaitPublisher(publisher, when: {
            clock.currentTimeProvider.modify { $0 = 301 }
            sut.recalculate()
            clock.currentTimeProvider.modify { $0 = 330 }
            sut.recalculate()
        })
        XCTAssertEqual(values, [
            OTPCodeTimerState(startTime: 30, endTime: 60), // initial time
            OTPCodeTimerState(startTime: 300, endTime: 330),
            OTPCodeTimerState(startTime: 330, endTime: 360),
        ])
    }

    @MainActor
    func test_recalculate_publishesDuplicateStatesIfRecalculatingInSamePeriod() async throws {
        let (_, _, sut) = makeSUT(clock: 32, period: 30)

        let publisher = sut.timerUpdatedPublisher().collectFirst(3)

        let values = try await awaitPublisher(publisher, when: {
            sut.recalculate()
            sut.recalculate()
        })
        XCTAssertEqual(values, [
            OTPCodeTimerState(startTime: 30, endTime: 60), // initial time
            OTPCodeTimerState(startTime: 30, endTime: 60),
            OTPCodeTimerState(startTime: 30, endTime: 60),
        ])
    }

    // MARK: - Helpers

    @MainActor
    private func makeSUT(
        clock clockTime: Double,
        period: UInt64,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (EpochClockMock, IntervalTimerMock, any OTPCodeTimerUpdater) {
        let timer = IntervalTimerMock()
        let clock = EpochClockMock(currentTime: clockTime)
        let sut = OTPCodeTimerUpdaterImpl(timer: timer, period: period, clock: clock)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (clock, timer, sut)
    }
}
