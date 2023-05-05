import Combine
import Foundation
import OTPFeed

struct MockCodeTimerUpdater: CodeTimerUpdater {
    let subject = PassthroughSubject<OTPTimerState, Never>()
    func timerUpdatedPublisher() -> AnyPublisher<OTPTimerState, Never> {
        subject.eraseToAnyPublisher()
    }
}
