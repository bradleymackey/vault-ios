import Foundation
import FoundationExtensions
import SwiftUI
import VaultCore
import VaultFeed
import VaultSettings
@testable import VaultiOS

@MainActor
func anyVaultDataModel(
    vaultStore: any VaultStore = VaultStoreStub(),
    vaultTagStore: any VaultTagStore = VaultTagStoreStub(),
    backupPasswordStore: any BackupPasswordStore = BackupPasswordStoreMock(),
    backupEventLogger: any BackupEventLogger = BackupEventLoggerMock()
) -> VaultDataModel {
    VaultDataModel(
        vaultStore: vaultStore,
        vaultTagStore: vaultTagStore,
        backupPasswordStore: backupPasswordStore,
        backupEventLogger: backupEventLogger
    )
}

func anyVaultItemTag(
    id: UUID = UUID(),
    name: String = "name",
    color: VaultItemColor = .tagDefault,
    iconName: String = VaultItemTag.defaultIconName
) -> VaultItemTag {
    VaultItemTag(id: .init(id: id), name: name, color: color, iconName: iconName)
}

extension VaultItemPreviewViewGeneratorMock {
    static func defaultMock() -> VaultItemPreviewViewGeneratorMock {
        mockGenerating {
            Text("Preview View")
        }
    }

    /// The preview view will be generated with the provided view.
    static func mockGenerating(@ViewBuilder view: @escaping () -> some View) -> VaultItemPreviewViewGeneratorMock {
        let s = VaultItemPreviewViewGeneratorMock()
        s.makeVaultPreviewViewHandler = { _, _, _ in
            AnyView(
                view()
            )
        }
        return s
    }
}

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

func uniqueVaultItem() -> VaultItem {
    VaultItem(
        metadata: uniqueMetadata(),
        item: .otpCode(uniqueCode())
    )
}

func anySecureNote() -> SecureNote {
    .init(title: "Hello World", contents: "This is my note", format: .markdown)
}

func uniqueMetadata(id: Identifier<VaultItem> = Identifier<VaultItem>()) -> VaultItem.Metadata {
    .init(
        id: id,
        created: Date(),
        updated: Date(),
        relativeOrder: .min,
        userDescription: "any",
        tags: [],
        visibility: .always,
        searchableLevel: .full,
        searchPassphrase: nil,
        lockState: .notLocked,
        color: nil
    )
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
