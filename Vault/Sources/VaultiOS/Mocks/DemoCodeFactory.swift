import Foundation
import VaultFeed

enum DemoVaultFactory {
    static func totpCode(issuer: String = "Ebay") -> VaultItem {
        .init(
            metadata: .init(
                id: .new(),
                created: Date(),
                updated: Date(),
                relativeOrder: .min,
                userDescription: "My Cool Code",
                tags: [],
                visibility: .always,
                searchableLevel: .full,
                searchPassphrase: "",
                lockState: .notLocked,
                color: nil
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

    static func hotpCode(issuer: String = "Ebay") -> VaultItem {
        .init(
            metadata: .init(
                id: .new(),
                created: Date(),
                updated: Date(),
                relativeOrder: .min,
                userDescription: "My Other Cool code",
                tags: [],
                visibility: .always,
                searchableLevel: .full,
                searchPassphrase: "",
                lockState: .notLocked,
                color: VaultItemColor(color: .green)
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

    static func secureNote(title: String = "Title", contents: String = "Contents...") -> VaultItem {
        .init(
            metadata: .init(
                id: .new(),
                created: Date(),
                updated: Date(),
                relativeOrder: .min,
                userDescription: "This is a secure note which I made. The contents should be very secret.",
                tags: [],
                visibility: .always,
                searchableLevel: .full,
                searchPassphrase: "",
                lockState: .notLocked,
                color: VaultItemColor(color: .red)
            ),
            item: .secureNote(.init(title: title, contents: contents, format: .markdown))
        )
    }
}
