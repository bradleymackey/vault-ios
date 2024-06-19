import Foundation
import SwiftUI
import VaultCore
import VaultFeed
import VaultSettings

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

func uniqueStoredVaultItem() -> StoredVaultItem {
    StoredVaultItem(
        metadata: uniqueMetadata(),
        item: .otpCode(uniqueCode())
    )
}

func anySecureNote() -> SecureNote {
    .init(title: "Hello World", contents: "This is my note")
}

func uniqueMetadata(id: UUID = UUID()) -> StoredVaultItem.Metadata {
    .init(
        id: id,
        created: Date(),
        updated: Date(),
        userDescription: "any",
        searchableLevel: .fullySearchable,
        color: nil
    )
}

func uniqueWritableVaultItem() -> StoredVaultItem.Write {
    .init(userDescription: "any", color: nil, item: .otpCode(uniqueCode()), searchableLevel: .fullySearchable)
}

func forceRunLoopAdvance() {
    RunLoop.main.run(until: Date().addingTimeInterval(0.1))
}

func nonPersistentDefaults() -> Defaults {
    let name = UUID().uuidString
    let user = UserDefaults(suiteName: name)
    user?.removePersistentDomain(forName: name)
    return Defaults(userDefaults: user!)
}

extension View {
    func framedToTestDeviceSize() -> some View {
        // iPhone 14 size
        frame(width: 390, height: 844)
    }
}
