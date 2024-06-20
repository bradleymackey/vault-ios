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
        let store = MockOTPCodeStore()
        let viewModel = FeedViewModel(store: store)
        let sut = makeSUT(viewModel: viewModel)
            .framedToTestDeviceSize()

        await viewModel.onAppear()

        assertSnapshot(matching: sut, as: .image)
    }

    @MainActor
    func test_layout_singleCodeAtMediumSize() async throws {
        let store = MockOTPCodeStore()
        store.codesToRetrieve = .init(items: [uniqueStoredVaultItem()])
        let viewModel = FeedViewModel(store: store)
        let sut = makeSUT(viewModel: viewModel)
            .framedToTestDeviceSize()

        await viewModel.onAppear()

        assertSnapshot(matching: sut, as: .image)
    }

    @MainActor
    func test_layout_multipleCodesAtMediumSize() async throws {
        let store = MockOTPCodeStore()
        store.codesToRetrieve = .init(items: [
            uniqueStoredVaultItem(),
            uniqueStoredVaultItem(),
            uniqueStoredVaultItem(),
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
    typealias SUT = VaultItemFeedView<MockOTPCodeStore, MockGenericViewGenerator>

    @MainActor
    private func makeSUT(
        viewModel: FeedViewModel<MockOTPCodeStore>,
        localSettings: LocalSettings = LocalSettings(defaults: nonPersistentDefaults())
    ) -> SUT {
        let generator = MockGenericViewGenerator()
        return VaultItemFeedView(
            viewModel: viewModel,
            localSettings: localSettings,
            viewGenerator: generator,
            isEditing: .constant(false)
        )
    }
}
