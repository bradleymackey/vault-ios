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
}
