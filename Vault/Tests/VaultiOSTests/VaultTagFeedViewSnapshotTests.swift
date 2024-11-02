import Foundation
import SnapshotTesting
import SwiftUI
import VaultFeed
import XCTest
@testable import VaultiOS

final class VaultTagFeedViewSnapshotTests: XCTestCase {
    @MainActor
    func test_layout_noTags() async {
        let sut = await makeSUT()
            .framedToTestDeviceSize()

        assertSnapshot(of: sut, as: .image)
    }

    @MainActor
    func test_layout_multipleTags() async {
        let vaultTagStore = VaultTagStoreStub()
        vaultTagStore.retrieveTagsHandler = {
            [
                anyVaultItemTag(name: "A", color: .gray, iconName: "tag.fill"),
                anyVaultItemTag(name: "Barcellos", color: .tagDefault, iconName: "person.fill"),
                anyVaultItemTag(name: "Zoo", color: .gray, iconName: "tag.fill"),
                anyVaultItemTag(name: "Crayfish", color: .gray, iconName: "tag.fill"),
            ]
        }
        let sut = await makeSUT(vaultTagStore: vaultTagStore)
            .framedToTestDeviceSize()

        assertSnapshot(of: sut, as: .image)
    }
}

// MARK: - Helpers

extension VaultTagFeedViewSnapshotTests {
    @MainActor
    private func makeSUT(
        vaultTagStore: any VaultTagStore = VaultTagStoreStub()
    ) async -> some View {
        let dataModel = VaultDataModel(
            vaultStore: VaultStoreStub(),
            vaultTagStore: vaultTagStore,
            vaultImporter: VaultStoreImporterMock(),
            vaultDeleter: VaultStoreDeleterMock(),
            vaultKillphraseDeleter: VaultStoreKillphraseDeleterMock(),
            backupPasswordStore: BackupPasswordStoreMock(),
            backupEventLogger: BackupEventLoggerMock()
        )
        await dataModel.reloadData()
        return VaultTagFeedView(viewModel: .init())
            .environment(dataModel)
    }
}
