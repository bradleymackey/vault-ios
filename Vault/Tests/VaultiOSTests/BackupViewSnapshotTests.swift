import Foundation
import SwiftUI
import TestHelpers
import Testing
import VaultFeed
@testable import VaultiOS

@MainActor
struct BackupViewSnapshotTests {
    @Test
    func backupPasswordNotFetched() async throws {
        let sut = makeSUT(dataModel: anyVaultDataModel())
            .framedForTest()

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func backupPasswordError() async {
        let backupPasswordStore = BackupPasswordStoreMock()
        backupPasswordStore.fetchPasswordHandler = { throw TestError() }
        let dataModel = anyVaultDataModel(backupPasswordStore: backupPasswordStore)
        await dataModel.loadBackupPassword()
        await dataModel.reloadData()

        let sut = makeSUT(dataModel: dataModel)
            .framedForTest()

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func backupPasswordNotCreated_noItems() async {
        let vaultStore = VaultStoreStub()
        vaultStore.hasAnyItemsHandler = { false }
        let backupPasswordStore = BackupPasswordStoreMock()
        backupPasswordStore.fetchPasswordHandler = { nil }
        let dataModel = anyVaultDataModel(vaultStore: vaultStore, backupPasswordStore: backupPasswordStore)
        await dataModel.loadBackupPassword()
        await dataModel.reloadData()

        let sut = makeSUT(dataModel: dataModel)
            .framedForTest()

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func backupPasswordNotCreated_hasItems() async {
        let vaultStore = VaultStoreStub()
        vaultStore.hasAnyItemsHandler = { true }
        let backupPasswordStore = BackupPasswordStoreMock()
        backupPasswordStore.fetchPasswordHandler = { nil }
        let dataModel = anyVaultDataModel(vaultStore: vaultStore, backupPasswordStore: backupPasswordStore)
        await dataModel.loadBackupPassword()
        await dataModel.reloadData()

        let sut = makeSUT(dataModel: dataModel)
            .framedForTest()

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func backupPasswordFetched_noItems() async {
        let vaultStore = VaultStoreStub()
        vaultStore.hasAnyItemsHandler = { false }
        let backupPasswordStore = BackupPasswordStoreMock()
        backupPasswordStore.fetchPasswordHandler = { .init(
            key: .random(),
            salt: .random(count: 32),
            keyDervier: .testing
        ) }
        let dataModel = anyVaultDataModel(vaultStore: vaultStore, backupPasswordStore: backupPasswordStore)
        await dataModel.loadBackupPassword()
        await dataModel.reloadData()

        let sut = makeSUT(dataModel: dataModel)
            .framedForTest()

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func backupPasswordFetched_hasItems() async {
        let vaultStore = VaultStoreStub()
        vaultStore.hasAnyItemsHandler = { true }
        let backupPasswordStore = BackupPasswordStoreMock()
        backupPasswordStore.fetchPasswordHandler = { .init(
            key: .random(),
            salt: .random(count: 32),
            keyDervier: .testing
        ) }
        let dataModel = anyVaultDataModel(vaultStore: vaultStore, backupPasswordStore: backupPasswordStore)
        await dataModel.loadBackupPassword()
        await dataModel.reloadData()

        let sut = makeSUT(dataModel: dataModel)
            .framedForTest()

        assertSnapshot(of: sut, as: .image)
    }
}

extension BackupViewSnapshotTests {
    private func makeSUT(
        dataModel: VaultDataModel
    ) -> some View {
        let injector = anyVaultInjector()
        return BackupView()
            .environment(dataModel)
            .environment(DeviceAuthenticationService(policy: .alwaysAllow))
            .environment(injector)
    }
}
