import Combine
import Foundation
import SwiftUI
import VaultCore
import VaultFeed

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

    func retrieve(query _: VaultStoreQuery) async throws -> VaultRetrievalResult<VaultItem> {
        .init(items: codes)
    }
}
