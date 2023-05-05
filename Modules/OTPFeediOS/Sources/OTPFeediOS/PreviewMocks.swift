import Combine
import Foundation
import OTPFeed

struct MockCodeTimerUpdater: CodeTimerUpdater {
    let subject = PassthroughSubject<OTPTimerState, Never>()
    func timerUpdatedPublisher() -> AnyPublisher<OTPTimerState, Never> {
        subject.eraseToAnyPublisher()
    }
}

struct OTPCodeRendererMock: OTPCodeRenderer {
    let subject = PassthroughSubject<String, Error>()
    func renderedCodePublisher() -> AnyPublisher<String, Error> {
        subject.eraseToAnyPublisher()
    }
}

func forceRunLoopAdvance() {
    RunLoop.main.run(until: Date())
}
