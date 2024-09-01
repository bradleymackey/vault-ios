import Combine
import Foundation
import TestHelpers
import VaultCore
import VaultFeed
import XCTest

final class OTPCodeTimerUpdaterImplTests: XCTestCase {
    @MainActor
    func test_timerUpdatedPublisher_publishesInitialValueImmediately() async throws {
        let clock = EpochClockMock(currentTime: 62)
        let sut = makeSUT(clock: clock, period: 30)

        let publisher = sut.timerUpdatedPublisher().collectFirst(1)

        let values = try await awaitPublisher(publisher, when: {
            // noop
        })
        XCTAssertEqual(values, [OTPCodeTimerState(startTime: 60, endTime: 90)])
    }

    @MainActor
    func test_timerUpdatedPublisher_publishesStateForCurrentTimeOnTimerFinish() async throws {
        let clock = EpochClockMock(currentTime: 32)
        let timer = IntervalTimerMock()
        let sut = makeSUT(clock: clock, timer: timer, period: 30)

        let publisher = sut.timerUpdatedPublisher().collectFirst(2)

        let values = try await awaitPublisher(publisher, when: {
            clock.currentTime = 62
            await timer.finishTimer()
        })
        XCTAssertEqual(values, [
            OTPCodeTimerState(startTime: 30, endTime: 60), // initial time
            OTPCodeTimerState(startTime: 60, endTime: 90),
        ])
    }

    @MainActor
    func test_recalculate_forcesPublishOfCurrentTimerState() async throws {
        let clock = EpochClockMock(currentTime: 32)
        let timer = IntervalTimerMock()
        let sut = makeSUT(clock: clock, timer: timer, period: 30)

        let publisher = sut.timerUpdatedPublisher().collectFirst(3)

        let values = try await awaitPublisher(publisher, when: {
            clock.currentTime = 301
            sut.recalculate()
            clock.currentTime = 330
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
        let clock = EpochClockMock(currentTime: 32)
        let sut = makeSUT(clock: clock, period: 30)

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

    @MainActor
    func test_deinit_doesNotLeak() async throws {
        let clock = EpochClockMock(currentTime: 30)
        _ = makeSUT(clock: clock, period: 30)
    }

    // MARK: - Helpers

    @MainActor
    private func makeSUT(
        clock: EpochClockMock,
        timer: IntervalTimerMock = IntervalTimerMock(),
        period: UInt64,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OTPCodeTimerUpdaterImpl {
        let sut = OTPCodeTimerUpdaterImpl(timer: timer, period: period, clock: clock)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(clock, file: file, line: line)
        trackForMemoryLeaks(timer, file: file, line: line)
        return sut
    }
}
