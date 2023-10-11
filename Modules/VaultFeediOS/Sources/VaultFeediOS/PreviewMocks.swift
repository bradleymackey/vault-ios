import Combine
import Foundation
import VaultFeed

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

struct CodeStoreFake: VaultStoreReader {
    let codes: [StoredVaultItem] = [
        .init(
            id: UUID(),
            created: Date(),
            updated: Date(),
            userDescription: "",
            item: .otpCode(
                .init(
                    type: .totp(),
                    data: .init(
                        secret: .empty(),
                        accountName: "test@example.com",
                        issuer: "Ebay"
                    )
                )
            )
        ),
        .init(
            id: UUID(),
            created: Date(),
            updated: Date(),
            userDescription: "",
            item: .otpCode(
                .init(
                    type: .totp(),
                    data: .init(
                        secret: .empty(),
                        accountName: "test@example.com",
                        issuer: "Ebay"
                    )
                )
            )
        ),
        .init(
            id: UUID(),
            created: Date(), updated: Date(), userDescription: "",
            item: .otpCode(
                .init(
                    type: .hotp(counter: 0),
                    data: .init(
                        secret: .empty(),
                        accountName: "test@example.com",
                        issuer: "Ebay"
                    )
                )
            )
        ),
    ]

    func retrieve() async throws -> [StoredVaultItem] {
        codes
    }
}
