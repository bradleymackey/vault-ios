import Foundation
import FoundationExtensions
import VaultCore
import VaultFeed

func anyNSError() -> NSError {
    NSError(domain: "any", code: 100)
}

func uniqueCode() -> GenericOTPAuthCode {
    let randomData = Data.random(count: 50)
    return GenericOTPAuthCode(
        type: .totp(),
        data: .init(
            secret: .init(data: randomData, format: .base32),
            accountName: "Some Account"
        )
    )
}

func uniqueStoredVaultItem() -> StoredVaultItem {
    StoredVaultItem(
        metadata: .init(
            id: UUID(), created: Date(), updated: Date(), userDescription: "any"
        ),
        item: .otpCode(uniqueCode())
    )
}

func uniqueVaultItem(item: VaultItem) -> StoredVaultItem {
    StoredVaultItem(
        metadata: .init(
            id: UUID(), created: Date(), updated: Date(), userDescription: "any"
        ),
        item: item
    )
}

func uniqueWritableVaultItem() -> StoredVaultItem.Write {
    .init(userDescription: "any", item: .otpCode(uniqueCode()))
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
