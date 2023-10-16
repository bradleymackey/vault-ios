import Foundation
import VaultFeed

enum DemoVaultFactory {
    static func totpCode(issuer: String = "Ebay") -> StoredVaultItem {
        .init(
            metadata: .init(
                id: UUID(),
                created: Date(),
                updated: Date(),
                userDescription: "My Cool Code"
            ),
            item: .otpCode(.init(
                type: .totp(),
                data: .init(
                    secret: .empty(),
                    accountName: "example@example.com",
                    issuer: issuer
                )
            ))
        )
    }

    static func hotpCode(issuer: String = "Ebay") -> StoredVaultItem {
        .init(
            metadata: .init(
                id: UUID(),
                created: Date(),
                updated: Date(),
                userDescription: "My Other Cool code"
            ),
            item: .otpCode(.init(
                type: .hotp(),
                data: .init(
                    secret: .empty(),
                    accountName: "HOTP test",
                    issuer: issuer
                )
            ))
        )
    }

    static func secureNote(title: String = "Title", contents: String = "Contents...") -> StoredVaultItem {
        .init(
            metadata: .init(
                id: UUID(),
                created: Date(),
                updated: Date(),
                userDescription: "This is a secure note"
            ),
            item: .secureNote(.init(title: title, contents: contents))
        )
    }
}
