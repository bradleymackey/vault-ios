import Foundation
import FoundationExtensions
import SwiftUI
import TestHelpers
import VaultFeed
import VaultiOS
import VaultSettings
import XCTest

final class VaultItemFeedViewSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
//        isRecording = true
    }

    @MainActor
    func test_layout_noCodes() async throws {
        let store = VaultStoreStub()
        let tagStore = VaultTagStoreStub()
        let dataModel = VaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        await dataModel.reloadData()

        let sut = makeSUT(dataModel: dataModel)
            .framedToTestDeviceSize()

        assertSnapshot(matching: sut, as: .image)
    }

    @MainActor
    func test_layout_singleCodeAtMediumSize() async throws {
        let store = VaultStoreStub()
        let tagStore = VaultTagStoreStub()
        store.retrieveQueryResult = .init(items: [uniqueVaultItem()])
        let dataModel = VaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        await dataModel.reloadData()

        let sut = makeSUT(dataModel: dataModel)
            .framedToTestDeviceSize()

        assertSnapshot(matching: sut, as: .image)
    }

    @MainActor
    func test_layout_multipleCodesAtMediumSize() async throws {
        let store = VaultStoreStub()
        let tagStore = VaultTagStoreStub()
        store.retrieveQueryResult = .init(items: [
            uniqueVaultItem(),
            uniqueVaultItem(),
            uniqueVaultItem(),
        ])
        let dataModel = VaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        await dataModel.reloadData()

        let sut = makeSUT(dataModel: dataModel)
            .framedToTestDeviceSize()

        assertSnapshot(matching: sut, as: .image)
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
        let dataModel = VaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        await dataModel.reloadData()

        let sut = makeSUT(dataModel: dataModel)
            .framedToTestDeviceSize()

        assertSnapshot(matching: sut, as: .image)
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
        let dataModel = VaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        await dataModel.reloadData()

        let sut = makeSUT(dataModel: dataModel)
            .framedToTestDeviceSize()

        dataModel.itemsFilteringByTags = [tag1Id]

        assertSnapshot(matching: sut, as: .image)
    }
}

// MARK: - Helpers

extension VaultItemFeedViewSnapshotTests {
    @MainActor
    private func makeSUT(
        dataModel: VaultDataModel,
        localSettings: LocalSettings = LocalSettings(defaults: nonPersistentDefaults())
    ) -> some View {
        let generator = VaultItemPreviewViewGeneratorMock.mockGenerating {
            ZStack {
                Color.blue
                Text("Code")
                    .foregroundStyle(.white)
            }
            .frame(minHeight: 100)
        }
        return VaultItemFeedView(
            localSettings: localSettings,
            viewGenerator: generator,
            isEditing: .constant(false)
        )
        .environment(dataModel)
    }
}
