import Foundation
import FoundationExtensions
import SwiftUI
import TestHelpers
import VaultFeed
import VaultSettings
import XCTest
@testable import VaultiOS

final class VaultItemFeedViewSnapshotTests: XCTestCase {
    @MainActor
    func test_layout_noCodes() async throws {
        let store = VaultStoreStub()
        let tagStore = VaultTagStoreStub()
        let dataModel = anyVaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        await dataModel.reloadData()

        let sut = makeSUT(dataModel: dataModel)
            .framedToTestDeviceSize()

        assertSnapshot(of: sut, as: .image)
    }

    @MainActor
    func test_layout_singleCodeAtMediumSize() async throws {
        let store = VaultStoreStub()
        let tagStore = VaultTagStoreStub()
        store.retrieveHandler = { _ in .init(items: [uniqueVaultItem()]) }
        let dataModel = anyVaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        await dataModel.reloadData()

        let sut = makeSUT(dataModel: dataModel)
            .framedToTestDeviceSize()

        assertSnapshot(of: sut, as: .image)
    }

    @MainActor
    func test_layout_multipleCodesAtMediumSize() async throws {
        let store = VaultStoreStub()
        let tagStore = VaultTagStoreStub()
        store.retrieveHandler = { _ in
            .init(items: [
                uniqueVaultItem(),
                uniqueVaultItem(),
                uniqueVaultItem(),
            ])
        }
        let dataModel = anyVaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        await dataModel.reloadData()

        let sut = makeSUT(dataModel: dataModel)
            .framedToTestDeviceSize()

        assertSnapshot(of: sut, as: .image)
    }

    @MainActor
    func test_viewState_toggleEditingMode() async throws {
        let state = VaultItemFeedState()
        let store = VaultStoreStub()
        let tagStore = VaultTagStoreStub()
        store.retrieveHandler = { _ in .init(items: [uniqueVaultItem()]) }
        let dataModel = anyVaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        await dataModel.reloadData()

        let sut = makeSUT(dataModel: dataModel, state: state)
            .framedToTestDeviceSize()

        state.isEditing = true
        assertSnapshot(of: sut, as: .image, named: "editing")

        state.isEditing = false
        assertSnapshot(of: sut, as: .image, named: "notEditing")
    }

    @MainActor
    func test_searchBar_includesTagsIfTheyExistInTheVaultStore() async throws {
        let store = VaultStoreStub()
        let tagStore = VaultTagStoreStub()
        tagStore.retrieveTagsHandler = {
            [
                VaultItemTag(id: .init(), name: "tag1"),
                VaultItemTag(id: .init(), name: "tag2", color: .gray),
            ]
        }
        let dataModel = anyVaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        await dataModel.reloadData()

        let sut = makeSUT(dataModel: dataModel)
            .framedToTestDeviceSize()

        assertSnapshot(of: sut, as: .image)
    }

    @MainActor
    func test_searchBar_tagsBeingFiltered() async throws {
        let store = VaultStoreStub()
        let tagStore = VaultTagStoreStub()
        let tag1Id = Identifier<VaultItemTag>()
        tagStore.retrieveTagsHandler = {
            [
                VaultItemTag(id: tag1Id, name: "tag1"),
                VaultItemTag(id: .init(), name: "tag2", color: .gray),
            ]
        }
        let dataModel = anyVaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        await dataModel.reloadData()

        let sut = makeSUT(dataModel: dataModel)
            .framedToTestDeviceSize()

        dataModel.itemsFilteringByTags = [tag1Id]

        assertSnapshot(of: sut, as: .image)
    }
}

// MARK: - Helpers

extension VaultItemFeedViewSnapshotTests {
    @MainActor
    private func makeSUT(
        dataModel: VaultDataModel,
        state: VaultItemFeedState = VaultItemFeedState(),
        // swiftlint:disable:next force_try
        localSettings: LocalSettings = LocalSettings(defaults: try! .nonPersistent())
    ) -> some View {
        struct CodePlaceholderView: View {
            var behaviour: VaultItemViewBehaviour

            var body: some View {
                VStack {
                    Text("Code")
                    Text("Placeholder")
                    switch behaviour {
                    case .normal: EmptyView()
                    case let .editingState(message):
                        Text("is editing").font(.caption)
                        if let message {
                            Text(message).font(.caption)
                        }
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1, contentMode: .fill)
                .background(Color.blue)
            }
        }
        let generator = VaultItemPreviewViewGeneratorMock.mockGenerating { _, _, behaviour in
            CodePlaceholderView(behaviour: behaviour)
        }
        return VaultItemFeedView(
            localSettings: localSettings,
            viewGenerator: generator,
            state: state
        )
        .environment(dataModel)
        .environment(VaultInjector(
            clock: EpochClockMock(currentTime: 30),
            intervalTimer: IntervalTimerMock(),
            backupEventLogger: BackupEventLoggerMock(),
            vaultKeyDeriverFactory: VaultKeyDeriverFactoryMock(),
            encryptedVaultDecoder: EncryptedVaultDecoderMock(),
            defaults: Defaults(userDefaults: .standard),
            fileManager: FileManager()
        ))
    }
}
