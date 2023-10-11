import Foundation
import OTPFeed
import OTPFeediOS
import VaultSettings
import SwiftUI
import TestHelpers
import XCTest

@MainActor
final class OTPCodeFeedViewSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        isRecording = false
    }

    func test_layout_noCodes() async throws {
        let store = MockOTPCodeStore()
        let viewModel = FeedViewModel(store: store)
        let sut = makeSUT(viewModel: viewModel)
            .framedToTestDeviceSize()

        await viewModel.onAppear()

        assertSnapshot(matching: sut, as: .image)
    }

    func test_layout_singleCodeAtMediumSize() async throws {
        let store = MockOTPCodeStore()
        store.codesToRetrieve = [uniqueStoredCode()]
        let viewModel = FeedViewModel(store: store)
        let sut = makeSUT(viewModel: viewModel)
            .framedToTestDeviceSize()

        await viewModel.onAppear()

        assertSnapshot(matching: sut, as: .image)
    }

    func test_layout_multipleCodesAtMediumSize() async throws {
        let store = MockOTPCodeStore()
        store.codesToRetrieve = [uniqueStoredCode(), uniqueStoredCode(), uniqueStoredCode()]
        let viewModel = FeedViewModel(store: store)
        let sut = makeSUT(viewModel: viewModel)
            .framedToTestDeviceSize()

        await viewModel.onAppear()

        assertSnapshot(matching: sut, as: .image)
    }

    func test_layout_singleCodeAtLargeSize() async throws {
        let store = MockOTPCodeStore()
        store.codesToRetrieve = [uniqueStoredCode()]
        let viewModel = FeedViewModel(store: store)
        let settings = LocalSettings(defaults: nonPersistentDefaults())
        settings.state.previewSize = .large
        let sut = makeSUT(viewModel: viewModel, localSettings: settings)
            .framedToTestDeviceSize()

        await viewModel.onAppear()

        assertSnapshot(matching: sut, as: .image)
    }

    func test_layout_multipleCodesAtLargeSize() async throws {
        let store = MockOTPCodeStore()
        store.codesToRetrieve = [uniqueStoredCode(), uniqueStoredCode(), uniqueStoredCode()]
        let viewModel = FeedViewModel(store: store)
        let settings = LocalSettings(defaults: nonPersistentDefaults())
        settings.state.previewSize = .large
        let sut = makeSUT(viewModel: viewModel, localSettings: settings)
            .framedToTestDeviceSize()

        await viewModel.onAppear()

        assertSnapshot(matching: sut, as: .image)
    }
}

// MARK: - Helpers

extension OTPCodeFeedViewSnapshotTests {
    typealias SUT = OTPCodeFeedView<MockOTPCodeStore, MockGenericViewGenerator>
    private func makeSUT(
        viewModel: FeedViewModel<MockOTPCodeStore>,
        localSettings: LocalSettings = LocalSettings(defaults: nonPersistentDefaults())
    ) -> SUT {
        let generator = MockGenericViewGenerator()
        return OTPCodeFeedView(
            viewModel: viewModel,
            localSettings: localSettings,
            viewGenerator: generator,
            isEditing: .constant(false)
        )
    }
}
