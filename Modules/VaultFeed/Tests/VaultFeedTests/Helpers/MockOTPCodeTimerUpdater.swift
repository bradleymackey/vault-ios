import Combine
import Foundation
import VaultFeed

final class MockOTPCodeTimerUpdater: OTPCodeTimerUpdater {
    let subject = PassthroughSubject<OTPCodeTimerState, Never>()
    var recalculateCallCount = 0
    func timerUpdatedPublisher() -> AnyPublisher<OTPCodeTimerState, Never> {
        subject.eraseToAnyPublisher()
    }

    func recalculate() {
        recalculateCallCount += 1
    }
}
