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

struct MockCodeStore: OTPCodeStoreReader {
    let codes: [StoredOTPCode] = [
        .init(id: UUID(), code: .init(secret: .empty(), accountName: "Test 1")),
        .init(id: UUID(), code: .init(secret: .empty(), accountName: "Test 2")),
        .init(id: UUID(), code: .init(type: .hotp(counter: 0), secret: .empty(), accountName: "Test 3")),
    ]

    func retrieve() async throws -> [OTPFeed.StoredOTPCode] {
        codes
    }
}
