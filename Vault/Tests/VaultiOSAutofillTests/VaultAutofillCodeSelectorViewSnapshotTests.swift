import Foundation
import SwiftUI
import TestHelpers
import Testing
import VaultFeed
import VaultiOS
import VaultSettings
@testable import VaultiOSAutofill

@MainActor
struct VaultAutofillCodeSelectorViewSnapshotTests {
    @Test
    func layout() async throws {
        let settings = try LocalSettings(defaults: .nonPersistent())
        let generator = VaultItemPreviewViewGeneratorMock()
        generator.makeVaultPreviewViewHandler = { _, _, _ in AnyView(Text("Code Placeholder")) }

        let injector = try VaultInjector(
            clock: EpochClockMock(currentTime: 100),
            intervalTimer: IntervalTimerMock(),
            backupEventLogger: BackupEventLoggerMock(),
            vaultKeyDeriverFactory: VaultKeyDeriverFactoryMock(),
            encryptedVaultDecoder: EncryptedVaultDecoderMock(),
            defaults: .nonPersistent(),
            fileManager: .default
        )

        let store = VaultStoreStub()
        store.retrieveHandler = { _ in .init(items: [anyVaultItem(), anyVaultItem(), anyVaultItem()]) }
        let tagStore = VaultTagStoreStub()
        let dataModel = VaultDataModel(
            vaultStore: store,
            vaultTagStore: tagStore,
            vaultImporter: VaultStoreImporterMock(),
            vaultDeleter: VaultStoreDeleterMock(),
            backupPasswordStore: BackupPasswordStoreMock(),
            backupEventLogger: BackupEventLoggerMock()
        )
        await dataModel.reloadData()
        let sut = VaultAutofillCodeSelectorView(
            localSettings: settings,
            viewGenerator: generator,
            copyActionHandler: VaultItemCopyActionHandlerMock(),
            textToInsertSubject: .init(),
            cancelSubject: .init()
        )
        .environment(injector)
        .environment(dataModel)
        .environment(DeviceAuthenticationService(policy: .alwaysAllow))
        .framedToTestDeviceSize()

        assertSnapshot(of: sut, as: .image)
    }
}
