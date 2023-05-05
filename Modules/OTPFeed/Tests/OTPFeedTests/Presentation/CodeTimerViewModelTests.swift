import Combine
import Foundation
import OTPCore
import OTPFeed
import XCTest

final class CodeTimerViewModelTests: XCTestCase {
    func test_timeUpdated_setsTimerStateOnPublish() async throws {
        let (timer, sut) = makeSUT(initialTime: 100)
        let publisher = sut.$timer.collectNext(1)
        let timeValue = anyTimerState()

        let values = try await awaitPublisher(publisher, when: {
            timer.subject.send(timeValue)
        })
        XCTAssertEqual(values, [timeValue])
    }

    func test_updateDeinit_stillPublishesIfTimerInstanceLost() async throws {
        var timer: CodeTimerController<MockIntervalTimer>?
        var sut: CodeTimerViewModel<CodeTimerController<MockIntervalTimer>>?
        let intervalTimer = MockIntervalTimer()

        autoreleasepool {
            timer = CodeTimerController(timer: intervalTimer, period: 1, clock: EpochClock(makeCurrentTime: { 100 }))

            sut = CodeTimerViewModel(updater: timer!, clock: EpochClock(makeCurrentTime: { 100 }))
            timer = nil
        }

        let publisher = sut!.$timer.collectNext(1)

        let values = try await awaitPublisher(publisher, timeout: 1, when: {
            intervalTimer.finishTimer()
        })
        XCTAssertEqual(values, [OTPTimerState(startTime: 100, endTime: 101)])
    }

    // MARK: - Helpers

    private func makeSUT(
        initialTime: Double,
        file: StaticString = #file,
        line: UInt = #line
    ) -> (MockCodeTimerUpdater, CodeTimerViewModel<MockCodeTimerUpdater>) {
        let timer = MockCodeTimerUpdater()
        let sut = CodeTimerViewModel(updater: timer, clock: EpochClock(makeCurrentTime: { initialTime }))
        trackForMemoryLeaks(sut, file: file, line: line)
        return (timer, sut)
    }

    private func anyTimerState() -> OTPTimerState {
        OTPTimerState(startTime: 69, endTime: 420)
    }
}
