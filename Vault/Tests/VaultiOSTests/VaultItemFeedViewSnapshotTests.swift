import Foundation
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
        store.codes = .init(items: [uniqueVaultItem()])
        let viewModel = FeedViewModel(store: store)
        let sut = makeSUT(viewModel: viewModel)
            .framedToTestDeviceSize()

        await viewModel.onAppear()

        assertSnapshot(matching: sut, as: .image)
    }

    @MainActor
    func test_layout_multipleCodesAtMediumSize() async throws {
        let store = VaultStoreStub()
        store.codes = .init(items: [
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
