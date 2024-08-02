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
        let viewModel = FeedViewModel(store: store)
        let sut = makeSUT(viewModel: viewModel)
            .framedToTestDeviceSize()

        await viewModel.onAppear()

        assertSnapshot(matching: sut, as: .image)
    }

    @MainActor
    func test_layout_singleCodeAtMediumSize() async throws {
        let store = VaultStoreStub()
        store.retrieveQueryResult = .init(items: [uniqueVaultItem()])
        let viewModel = FeedViewModel(store: store)
        let sut = makeSUT(viewModel: viewModel)
            .framedToTestDeviceSize()

        await viewModel.onAppear()

        assertSnapshot(matching: sut, as: .image)
    }

    @MainActor
    func test_layout_multipleCodesAtMediumSize() async throws {
        let store = VaultStoreStub()
        store.retrieveQueryResult = .init(items: [
            uniqueVaultItem(),
            uniqueVaultItem(),
            uniqueVaultItem(),
        ])
        let viewModel = FeedViewModel(store: store)
        let sut = makeSUT(viewModel: viewModel)
            .framedToTestDeviceSize()

        await viewModel.onAppear()

        assertSnapshot(matching: sut, as: .image)
    }

    @MainActor
    func test_searchBar_includesTagsIfTheyExistInTheVaultStore() async throws {
        let store = VaultStoreStub()
        store.retrieveTagsResult = .success([
            VaultItemTag(id: .init(), name: "tag1"),
            VaultItemTag(id: .init(), name: "tag2", color: .gray),
        ])
        let viewModel = FeedViewModel(store: store)
        let sut = makeSUT(viewModel: viewModel)
            .framedToTestDeviceSize()

        await viewModel.onAppear()

        assertSnapshot(matching: sut, as: .image)
    }

    @MainActor
    func test_searchBar_tagsBeingFiltered() async throws {
        let store = VaultStoreStub()
        let tag1Id = Identifier<VaultItemTag>()
        store.retrieveTagsResult = .success([
            VaultItemTag(id: tag1Id, name: "tag1"),
            VaultItemTag(id: .init(), name: "tag2", color: .gray),
        ])
        let viewModel = FeedViewModel(store: store)
        let sut = makeSUT(viewModel: viewModel)
            .framedToTestDeviceSize()

        viewModel.filteringByTags = [tag1Id]

        await viewModel.onAppear()

        assertSnapshot(matching: sut, as: .image)
    }
}

// MARK: - Helpers

extension VaultItemFeedViewSnapshotTests {
    typealias SUT = VaultItemFeedView<VaultStoreStub, VaultItemPreviewViewGeneratorMock>

    @MainActor
    private func makeSUT(
        viewModel: FeedViewModel<VaultStoreStub>,
        localSettings: LocalSettings = LocalSettings(defaults: nonPersistentDefaults())
    ) -> SUT {
        let generator = VaultItemPreviewViewGeneratorMock.mockGenerating {
            ZStack {
                Color.blue
                Text("Code")
                    .foregroundStyle(.white)
            }
            .frame(minHeight: 100)
        }
        return VaultItemFeedView(
            viewModel: viewModel,
            localSettings: localSettings,
            viewGenerator: generator,
            isEditing: .constant(false)
        )
    }
}
