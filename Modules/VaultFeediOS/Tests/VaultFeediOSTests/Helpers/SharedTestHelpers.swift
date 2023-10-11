import Foundation
import SwiftUI
import VaultCore
import VaultFeed
import VaultSettings

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

func uniqueStoredCode() -> StoredVaultItem {
    StoredVaultItem(id: UUID(), created: Date(), updated: Date(), userDescription: "any", code: uniqueCode())
}

func uniqueWritableCode() -> StoredVaultItem.Write {
    .init(userDescription: "any", code: uniqueCode())
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
