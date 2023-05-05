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

    // MARK: - Helpers

    private func makeSUT(
        initialTime: Double,
        file: StaticString = #file,
        line: UInt = #line
    ) -> (MockCodeTimerUpdater, CodeTimerViewModel) {
        let timer = MockCodeTimerUpdater()
        let sut = CodeTimerViewModel(updater: timer, clock: EpochClock(makeCurrentTime: { initialTime }))
        trackForMemoryLeaks(sut, file: file, line: line)
        return (timer, sut)
    }

    private func anyTimerState() -> OTPTimerState {
        OTPTimerState(startTime: 69, endTime: 420)
    }
}
