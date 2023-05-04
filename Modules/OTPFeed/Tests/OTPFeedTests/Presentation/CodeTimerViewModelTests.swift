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

    private struct MockEpochClock: EpochClock {
        private let publisher: CurrentValueSubject<Double, Never>
        init(initialTime: Double) {
            publisher = CurrentValueSubject<Double, Never>(initialTime)
        }

        func tick() {
            publisher.send(publisher.value)
        }

        func send(time: Double) {
            publisher.send(time)
        }

        func secondsPublisher() -> AnyPublisher<Double, Never> {
            publisher.eraseToAnyPublisher()
        }

        var currentTime: Double {
            publisher.value
        }
    }
}
