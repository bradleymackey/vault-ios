import Combine
import Foundation
import VaultFeed

final class MockCodeTimerUpdater: CodeTimerUpdater {
    let subject = PassthroughSubject<OTPTimerState, Never>()
    var recalculateCallCount = 0
    func timerUpdatedPublisher() -> AnyPublisher<OTPTimerState, Never> {
        subject.eraseToAnyPublisher()
    }

    func recalculate() {
        recalculateCallCount += 1
    }
}
