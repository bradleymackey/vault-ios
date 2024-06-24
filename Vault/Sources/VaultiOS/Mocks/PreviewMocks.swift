import Combine
import Foundation
import SwiftUI
import VaultCore
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
    let codes: [VaultItem] = [
        .init(
            metadata: .init(
                id: UUID(),
                created: Date(),
                updated: Date(),
                userDescription: "",
                tags: [],
                visibility: .always,
                searchableLevel: .full,
                searchPassphrase: "",
                color: VaultItemColor(color: .green)
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
                userDescription: "",
                tags: [],
                visibility: .always,
                searchableLevel: .full,
                searchPassphrase: "",
                color: VaultItemColor(color: .green)
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
                userDescription: "",
                tags: [],
                visibility: .always,
                searchableLevel: .full,
                searchPassphrase: "",
                color: VaultItemColor(color: .green)
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

    func retrieve() async throws -> VaultRetrievalResult {
        .init(items: codes)
    }

    func retrieve(matching _: String) async throws -> VaultRetrievalResult {
        .init(items: codes)
    }
}

struct VaultItemPreviewViewGeneratorMock: VaultItemPreviewViewGenerator, VaultItemCopyActionHandler {
    typealias PreviewItem = VaultItem.Payload

    func makeVaultPreviewView(
        item _: PreviewItem,
        metadata _: VaultItem.Metadata,
        behaviour _: VaultItemViewBehaviour
    ) -> some View {
        Text("Preview View")
    }

    func textToCopyForVaultItem(id _: UUID) -> String? {
        nil
    }

    func scenePhaseDidChange(to _: ScenePhase) {
        // noop
    }

    func didAppear() {
        // noop
    }
}
