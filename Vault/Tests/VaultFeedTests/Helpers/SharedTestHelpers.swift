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
) -> StoredVaultItem.Metadata {
    .init(
        id: UUID(),
        created: Date(),
        updated: Date(),
        userDescription: userDescription,
        tags: .init(ids: []),
        visibility: .always,
        searchableLevel: .full,
        searchPassphrase: nil,
        color: nil
    )
}

func uniqueStoredVaultItem() -> StoredVaultItem {
    StoredVaultItem(
        metadata: uniqueStoredMetadata(),
        item: .otpCode(uniqueCode())
    )
}

func searchableStoredOTPVaultItem(
    userDescription: String = "",
    accountName: String = "",
    issuerName: String = "",
    visibility: VaultItemVisibility = .always,
    searchableLevel: VaultItemSearchableLevel = .full,
    searchPassphrase: String? = nil
) -> StoredVaultItem {
    StoredVaultItem(
        metadata: .init(
            id: UUID(),
            created: Date(),
            updated: Date(),
            userDescription: userDescription,
            tags: .init(ids: []),
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
    searchableLevel: VaultItemSearchableLevel = .full,
    secretPassphrase: String? = nil
) -> StoredVaultItem {
    StoredVaultItem(
        metadata: .init(
            id: UUID(),
            created: Date(),
            updated: Date(),
            userDescription: userDescription,
            tags: .init(ids: []),
            visibility: .always,
            searchableLevel: searchableLevel,
            searchPassphrase: secretPassphrase,
            color: nil
        ),
        item: .secureNote(.init(title: title, contents: contents))
    )
}

func uniqueVaultItem(item: VaultItem) -> StoredVaultItem {
    StoredVaultItem(
        metadata: uniqueStoredMetadata(),
        item: item
    )
}

func uniqueWritableVaultItem(visibility: VaultItemVisibility = .always) -> StoredVaultItem.Write {
    .init(
        userDescription: "any",
        color: nil,
        item: .otpCode(uniqueCode()),
        tags: .init(ids: []),
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
    searchPassphrase: String? = nil
) -> StoredVaultItem.Write {
    searchableStoredOTPVaultItem(
        userDescription: userDescription,
        accountName: accountName,
        issuerName: issuerName,
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
) -> StoredVaultItem.Write {
    .init(
        userDescription: userDescription,
        color: nil,
        item: .secureNote(.init(title: title, contents: contents)),
        tags: .init(ids: []),
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
