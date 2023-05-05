import Combine
import Foundation
import OTPFeed
import XCTest

final class CodeTimerViewModelTests: XCTestCase {
    func test_timeUpdated_setsTimerStateOnPublish() async throws {
        let (_, timer, sut) = makeSUT(initialTime: 100)
        let publisher = sut.$timer.collectNext(1)
        let timeValue = anyTimerState()

        let values = try await awaitPublisher(publisher, when: {
            timer.subject.send(timeValue)
        })
        XCTAssertEqual(values, [timeValue])
    }

    func test_timeUpdated_ticksClockOnTimerStatePublish() async throws {
        let (clock, timer, sut) = makeSUT(initialTime: 100)
        let publisher = sut.$timer.collectNext(3)
        var clockTicks = 0
        clock.didTick = { clockTicks += 1 }

        _ = try await awaitPublisher(publisher, when: {
            timer.subject.send(anyTimerState())
            timer.subject.send(anyTimerState())
            timer.subject.send(anyTimerState())
        })
        XCTAssertEqual(clockTicks, 3)
    }

    // MARK: - Helpers

    private func makeSUT(initialTime: Double) -> (MockEpochClock, MockCodeTimerUpdater, CodeTimerViewModel) {
        let clock = MockEpochClock(initialTime: initialTime)
        let timer = MockCodeTimerUpdater()
        let sut = CodeTimerViewModel(clock: clock, updater: timer)
        return (clock, timer, sut)
    }

    private struct MockCodeTimerUpdater: CodeTimerUpdater {
        let subject = PassthroughSubject<OTPTimerState, Never>()
        func timerUpdatedPublisher() -> AnyPublisher<OTPTimerState, Never> {
            subject.eraseToAnyPublisher()
        }
    }

    private func anyTimerState() -> OTPTimerState {
        OTPTimerState(startTime: 69, endTime: 420)
    }
}
