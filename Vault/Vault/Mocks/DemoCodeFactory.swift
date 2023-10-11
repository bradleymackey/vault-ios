import Foundation
import VaultFeed

enum DemoCodeFactory {
    static func totpCode(issuer: String = "Ebay") -> StoredVaultItem {
        .init(
            id: UUID(),
            created: Date(),
            updated: Date(),
            userDescription: "My Cool Code",
            code: .init(
                type: .totp(),
                data: .init(
                    secret: .empty(),
                    accountName: "example@example.com",
                    issuer: issuer
                )
            )
        )
    }

    static func hotpCode(issuer: String = "Ebay") -> StoredVaultItem {
        .init(
            id: UUID(),
            created: Date(),
            updated: Date(),
            userDescription: "My Other Cool code",
            code: .init(
                type: .hotp(),
                data: .init(
                    secret: .empty(),
                    accountName: "HOTP test",
                    issuer: issuer
                )
            )
        )
    }
}
