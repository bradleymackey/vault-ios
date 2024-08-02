import Foundation
import FoundationExtensions
import VaultCore
import VaultFeed

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

// MARK: - VaultItem

func anySecureNote(
    title: String = "",
    contents: String = ""
) -> SecureNote {
    SecureNote(title: title, contents: contents)
}

func anyOTPAuthCode(
    accountName: String = "",
    issuerName: String = ""
) -> OTPAuthCode {
    let randomData = Data.random(count: 50)
    return OTPAuthCode(
        type: .totp(),
        data: .init(
            secret: .init(data: randomData, format: .base32),
            accountName: accountName,
            issuer: issuerName
        )
    )
}

/// A unique vault item.
/// The default payload is any OTPAuthCode.
func uniqueVaultItem(
    item: VaultItem.Payload = .otpCode(anyOTPAuthCode()),
    relativeOrder: UInt64 = .max,
    updatedDate: Date = Date(),
    userDescription: String = "",
    visibility: VaultItemVisibility = .always,
    tags: Set<Identifier<VaultItemTag>> = [],
    lockState: VaultItemLockState = .notLocked
) -> VaultItem {
    VaultItem(
        metadata: anyVaultItemMetadata(
            relativeOrder: relativeOrder,
            updatedDate: updatedDate,
            userDescription: userDescription,
            visibility: visibility,
            tags: tags,
            lockState: lockState
        ),
        item: item
    )
}

/// A unique vault item with custom metadata.
/// The default payload is any OTPAuthCode.
func uniqueVaultItem(
    metadata: VaultItem.Metadata,
    item: VaultItem.Payload = .otpCode(anyOTPAuthCode())
) -> VaultItem {
    VaultItem(
        metadata: metadata,
        item: item
    )
}

func anyVaultItemMetadata(
    relativeOrder: UInt64 = .max,
    updatedDate: Date = Date(),
    userDescription: String = "",
    visibility: VaultItemVisibility = .always,
    tags: Set<Identifier<VaultItemTag>> = [],
    searchableLevel: VaultItemSearchableLevel = .full,
    searchPassphrase: String? = nil,
    lockState: VaultItemLockState = .notLocked
) -> VaultItem.Metadata {
    .init(
        id: .new(),
        created: Date(),
        updated: updatedDate,
        relativeOrder: relativeOrder,
        userDescription: userDescription,
        tags: tags,
        visibility: visibility,
        searchableLevel: searchableLevel,
        searchPassphrase: searchPassphrase,
        lockState: lockState,
        color: nil
    )
}

extension SecureNote {
    func wrapInAnyVaultItem(
        userDescription: String = "",
        visibility: VaultItemVisibility = .always,
        tags: Set<Identifier<VaultItemTag>> = [],
        searchableLevel: VaultItemSearchableLevel = .full,
        searchPassphrase: String? = nil,
        lockState: VaultItemLockState = .notLocked
    ) -> VaultItem {
        VaultItem(
            metadata: anyVaultItemMetadata(
                userDescription: userDescription,
                visibility: visibility,
                tags: tags,
                searchableLevel: searchableLevel,
                searchPassphrase: searchPassphrase,
                lockState: lockState
            ),
            item: .secureNote(self)
        )
    }
}

extension OTPAuthCode {
    func wrapInAnyVaultItem(
        userDescription: String = "",
        visibility: VaultItemVisibility = .always,
        tags: Set<Identifier<VaultItemTag>> = [],
        searchableLevel: VaultItemSearchableLevel = .full,
        searchPassphrase: String? = nil
    ) -> VaultItem {
        VaultItem(
            metadata: anyVaultItemMetadata(
                userDescription: userDescription,
                visibility: visibility,
                tags: tags,
                searchableLevel: searchableLevel,
                searchPassphrase: searchPassphrase
            ),
            item: .otpCode(self)
        )
    }
}

// MARK: - VaultItemTag

func anyVaultItemTag(
    id: UUID = UUID(),
    name: String = "name",
    color: VaultItemColor? = nil,
    iconName: String? = nil
) -> VaultItemTag {
    VaultItemTag(id: .init(id: id), name: name, color: color, iconName: iconName)
}

// MARK: - Constants

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

// MARK: - Misc

func anyNSError() -> NSError {
    NSError(domain: "any", code: 100)
}

struct TestError: Error {}
