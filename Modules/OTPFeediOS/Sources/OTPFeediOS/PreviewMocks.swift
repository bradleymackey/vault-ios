import Combine
import Foundation
import OTPFeed

final class MockCodeTimerUpdater: CodeTimerUpdater {
    var recalculateCallCount = 0
    let subject = PassthroughSubject<OTPTimerState, Never>()
    func timerUpdatedPublisher() -> AnyPublisher<OTPTimerState, Never> {
        subject.eraseToAnyPublisher()
    }

    func recalculate() {
        recalculateCallCount += 1
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

struct CodeStoreFake: OTPCodeStoreReader {
    let codes: [StoredOTPCode] = [
        .init(
            id: UUID(),
            created: Date(),
            updated: Date(),
            userDescription: "",
            code: .init(secret: .empty(), accountName: "test@example.com", issuer: "Ebay")
        ),
        .init(
            id: UUID(),
            created: Date(),
            updated: Date(),
            userDescription: "",
            code: .init(secret: .empty(), accountName: "example@example.com")
        ),
        .init(
            id: UUID(),
            created: Date(), updated: Date(), userDescription: "",
            code: .init(type: .hotp(counter: 0), secret: .empty(), accountName: "win@ein.com", issuer: "Google")
        ),
    ]

    func retrieve() async throws -> [OTPFeed.StoredOTPCode] {
        codes
    }
}
