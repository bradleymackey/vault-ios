import Combine
import Foundation
import VaultFeed

final class MockCodeTimerUpdater: OTPCodeTimerUpdater {
    var recalculateCallCount = 0
    let subject = PassthroughSubject<OTPCodeTimerState, Never>()
    func timerUpdatedPublisher() -> AnyPublisher<OTPCodeTimerState, Never> {
        subject.eraseToAnyPublisher()
    }

    func recalculate() {
        recalculateCallCount += 1
    }
}

struct OTPCodeRendererMock: OTPCodeRenderer {
    let subject = PassthroughSubject<String, any Error>()
    func renderedCodePublisher() -> AnyPublisher<String, any Error> {
        subject.eraseToAnyPublisher()
    }
}

func forceRunLoopAdvance() {
    RunLoop.main.run(until: Date())
}

struct CodeStoreFake: VaultStoreReader {
    let codes: [StoredVaultItem] = [
        .init(
            metadata: .init(
                id: UUID(),
                created: Date(),
                updated: Date(),
                userDescription: ""
            ),
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
            metadata: .init(
                id: UUID(),
                created: Date(),
                updated: Date(),
                userDescription: ""
            ),
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
            metadata: .init(
                id: UUID(),
                created: Date(),
                updated: Date(),
                userDescription: ""
            ),
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
