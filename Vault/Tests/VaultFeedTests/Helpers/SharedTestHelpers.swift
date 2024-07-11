import Foundation
import FoundationExtensions
import VaultCore
import VaultFeed

func anyNSError() -> NSError {
    NSError(domain: "any", code: 100)
}

func uniqueCode() -> OTPAuthCode {
    let randomData = Data.random(count: 50)
    return OTPAuthCode(
        type: .totp(),
        data: .init(
            secret: .init(data: randomData, format: .base32),
            accountName: "Some Account"
        )
    )
}

func anyStoredNote() -> SecureNote {
    SecureNote(title: "Some note", contents: "Some note contents")
}

func uniqueStoredMetadata(
    userDescription: String = "any"
) -> VaultItem.Metadata {
    .init(
        id: UUID(),
        created: Date(),
        updated: Date(),
        userDescription: userDescription,
        tags: [],
        visibility: .always,
        searchableLevel: .full,
        searchPassphrase: nil,
        color: nil
    )
}

func uniqueVaultItem() -> VaultItem {
    VaultItem(
        metadata: uniqueStoredMetadata(),
        item: .otpCode(uniqueCode())
    )
}

func searchableStoredOTPVaultItem(
    userDescription: String = "",
    accountName: String = "",
    issuerName: String = "",
    tags: Set<VaultItemTag.Identifier> = [],
    visibility: VaultItemVisibility = .always,
    searchableLevel: VaultItemSearchableLevel = .full,
    searchPassphrase: String? = nil
) -> VaultItem {
    VaultItem(
        metadata: .init(
            id: UUID(),
            created: Date(),
            updated: Date(),
            userDescription: userDescription,
            tags: tags,
            visibility: visibility,
            searchableLevel: searchableLevel,
            searchPassphrase: searchPassphrase,
            color: nil
        ),
        item: .otpCode(.init(
            type: .totp(period: 30),
            data: .init(secret: .empty(), accountName: accountName, issuer: issuerName)
        ))
    )
}

func searchableStoredSecureNoteVaultItem(
    userDescription: String = "",
    title: String = "",
    contents: String = "",
    tags: Set<VaultItemTag.Identifier> = [],
    searchableLevel: VaultItemSearchableLevel = .full,
    secretPassphrase: String? = nil
) -> VaultItem {
    VaultItem(
        metadata: .init(
            id: UUID(),
            created: Date(),
            updated: Date(),
            userDescription: userDescription,
            tags: tags,
            visibility: .always,
            searchableLevel: searchableLevel,
            searchPassphrase: secretPassphrase,
            color: nil
        ),
        item: .secureNote(.init(title: title, contents: contents))
    )
}

func uniqueVaultItem(item: VaultItem.Payload) -> VaultItem {
    VaultItem(
        metadata: uniqueStoredMetadata(),
        item: item
    )
}

func uniqueWritableVaultItem(
    visibility: VaultItemVisibility = .always,
    tags: Set<VaultItemTag.Identifier> = []
) -> VaultItem.Write {
    .init(
        userDescription: "any",
        color: nil,
        item: .otpCode(uniqueCode()),
        tags: tags,
        visibility: visibility,
        searchableLevel: .none,
        searchPassphase: nil
    )
}

func writableSearchableOTPVaultItem(
    userDescription: String = "",
    accountName: String = "",
    issuerName: String = "",
    visibility: VaultItemVisibility = .always,
    searchableLevel: VaultItemSearchableLevel = .full,
    tags: Set<VaultItemTag.Identifier> = [],
    searchPassphrase: String? = nil
) -> VaultItem.Write {
    searchableStoredOTPVaultItem(
        userDescription: userDescription,
        accountName: accountName,
        issuerName: issuerName,
        tags: tags,
        visibility: visibility,
        searchableLevel: searchableLevel,
        searchPassphrase: searchPassphrase
    ).asWritable
}

func writableSearchableNoteVaultItem(
    userDescription: String = "",
    title: String = "",
    contents: String = "",
    visibility: VaultItemVisibility = .always,
    searchableLevel: VaultItemSearchableLevel = .full,
    searchPassphrase: String? = nil
) -> VaultItem.Write {
    .init(
        userDescription: userDescription,
        color: nil,
        item: .secureNote(.init(title: title, contents: contents)),
        tags: [],
        visibility: visibility,
        searchableLevel: searchableLevel,
        searchPassphase: searchPassphrase
    )
}

func hotpRfcSecretData() -> Data {
    Data([
        0x31,
        0x32,
        0x33,
        0x34,
        0x35,
        0x36,
        0x37,
        0x38,
        0x39,
        0x30,
        0x31,
        0x32,
        0x33,
        0x34,
        0x35,
        0x36,
        0x37,
        0x38,
        0x39,
        0x30,
    ])
}
