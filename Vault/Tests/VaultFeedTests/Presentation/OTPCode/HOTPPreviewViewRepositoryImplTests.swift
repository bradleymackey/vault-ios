import Foundation
import TestHelpers
import XCTest
@testable import VaultFeed

final class HOTPPreviewViewRepositoryImplTests: XCTestCase {
    @MainActor
    func test_init_hasNoSideEffects() {
        let store = VaultStoreHOTPIncrementerMock()
        let sut = makeSUT(store: store)

        XCTAssertEqual(store.incrementCounterCallCount, 0)
        XCTAssertEqual(sut.cachedViewsCount, 0)
        XCTAssertEqual(sut.cachedRendererCount, 0)
        XCTAssertEqual(sut.cachedIncrementerCount, 0)
    }

    @MainActor
    func test_previewViewModel_initiallyExpired() {
        let sut = makeSUT()

        let viewModel = sut.previewViewModel(metadata: anyVaultItemMetadata(), code: anyHOTPCode())

        XCTAssertEqual(viewModel.code, .obfuscated(.expiry))
    }

    @MainActor
    func test_previewViewModel_returnsSameViewModelInstanceUsedCachedViewModels() {
        let sut = makeSUT()

        let sharedID = Identifier<VaultItem>.new()
        let viewModel1 = sut.previewViewModel(metadata: anyVaultItemMetadata(id: sharedID), code: anyHOTPCode())
        XCTAssertEqual(sut.cachedViewsCount, 1)
        let viewModel2 = sut.previewViewModel(metadata: anyVaultItemMetadata(id: sharedID), code: anyHOTPCode())
        XCTAssertEqual(sut.cachedViewsCount, 1)
        let viewModel3 = sut.previewViewModel(metadata: anyVaultItemMetadata(id: .new()), code: anyHOTPCode())
        XCTAssertEqual(sut.cachedViewsCount, 2)

        XCTAssertIdentical(viewModel1, viewModel2)
        XCTAssertNotIdentical(viewModel1, viewModel3, "View Model 3 has a different ID")
        XCTAssertNotIdentical(viewModel2, viewModel3, "View Model 3 has a different ID")
    }

    @MainActor
    func test_previewViewModel_returnsSameIncrementerInstanceUsedCachedViewModels() {
        let sut = makeSUT()

        let sharedID = Identifier<VaultItem>.new()
        let incrementer1 = sut.incrementerViewModel(id: sharedID, code: anyHOTPCode())
        XCTAssertEqual(sut.cachedIncrementerCount, 1)
        let incrementer2 = sut.incrementerViewModel(id: sharedID, code: anyHOTPCode())
        XCTAssertEqual(sut.cachedIncrementerCount, 1)
        let incrementer3 = sut.incrementerViewModel(id: .new(), code: anyHOTPCode())
        XCTAssertEqual(sut.cachedIncrementerCount, 2)

        XCTAssertIdentical(incrementer1, incrementer2)
        XCTAssertNotIdentical(incrementer1, incrementer3, "View Model 3 has a different ID")
        XCTAssertNotIdentical(incrementer2, incrementer3, "View Model 3 has a different ID")
    }

    @MainActor
    func test_textToCopyForVaultItem_isNilIfCacheEmpty() {
        let sut = makeSUT()

        let copyAction = sut.textToCopyForVaultItem(id: .new())

        XCTAssertNil(copyAction)
    }

    @MainActor
    func test_textToCopyForVaultItem_isNilWhenCodeIsObfuscated() {
        let sut = makeSUT()

        let id = Identifier<VaultItem>()
        _ = sut.previewViewModel(metadata: anyVaultItemMetadata(id: id), code: anyHOTPCode())
        let code = sut.textToCopyForVaultItem(id: id)

        XCTAssertNil(code, "Code is initially obfuscated, so this should be nil")
    }

    @MainActor
    func test_textToCopyForVaultItem_isCopyTextIfCodeHasBeenGenerated() {
        let sut = makeSUT()
        let id = Identifier<VaultItem>()
        let viewModel = sut.previewViewModel(metadata: anyVaultItemMetadata(id: id), code: anyHOTPCode())
        viewModel.update(code: .visible("123456"))

        let code = sut.textToCopyForVaultItem(id: id)

        XCTAssertEqual(code, .init(text: "123456", requiresAuthenticationToCopy: false))
    }

    @MainActor
    func test_textToCopyForVaultItem_requiresAuthenticationToCopyIfLocked() {
        let sut = makeSUT()
        let id = Identifier<VaultItem>()
        let viewModel = sut.previewViewModel(metadata: anyVaultItemMetadata(id: id), code: anyHOTPCode())
        viewModel.update(code: .locked(code: "123456"))

        let code = sut.textToCopyForVaultItem(id: id)

        XCTAssertEqual(code, .init(text: "123456", requiresAuthenticationToCopy: true))
    }

    @MainActor
    func test_expireAll_marksAllCachedViewsAsExpired() {
        let sut = makeSUT()
        let viewModel = sut.previewViewModel(metadata: anyVaultItemMetadata(), code: anyHOTPCode())

        viewModel.update(code: .visible("123456"))

        sut.expireAll()

        XCTAssertEqual(viewModel.code, .obfuscated(.expiry))
    }

    @MainActor
    func test_obfuscateForPrivacy_obfuscatesVisibleCodesForPrivacy() {
        let sut = makeSUT()
        let viewModel = sut.previewViewModel(metadata: anyVaultItemMetadata(), code: anyHOTPCode())

        viewModel.update(code: .visible("123456"))

        sut.obfuscateForPrivacy()

        XCTAssertEqual(viewModel.code, .obfuscated(.privacy))
    }

    @MainActor
    func test_unobfuscateForPrivacy_unobfuscatesCodesHiddenForPrivacy() {
        let sut = makeSUT()
        let viewModel = sut.previewViewModel(metadata: anyVaultItemMetadata(), code: anyHOTPCode())

        viewModel.update(code: .visible("123456"))
        viewModel.obfuscateCodeForPrivacy()

        sut.unobfuscateForPrivacy()

        XCTAssertEqual(viewModel.code, .visible("123456"))
    }

    @MainActor
    func test_invalidateVaultItemDetailCache_removesItemsMatchingIDFromCache() async {
        let sut = makeSUT()

        let id1 = Identifier<VaultItem>()
        let id2 = Identifier<VaultItem>()

        _ = sut.previewViewModel(metadata: anyVaultItemMetadata(id: id1), code: anyHOTPCode())
        _ = sut.previewViewModel(metadata: anyVaultItemMetadata(id: id2), code: anyHOTPCode())
        _ = sut.incrementerViewModel(id: id1, code: anyHOTPCode())
        _ = sut.incrementerViewModel(id: id2, code: anyHOTPCode())

        XCTAssertEqual(sut.cachedViewsCount, 2)
        XCTAssertEqual(sut.cachedRendererCount, 2)
        XCTAssertEqual(sut.cachedIncrementerCount, 2)

        await sut.invalidateVaultItemDetailCache(forVaultItemWithID: id1)

        XCTAssertEqual(sut.cachedViewsCount, 1)
        XCTAssertEqual(sut.cachedRendererCount, 1)
        XCTAssertEqual(sut.cachedIncrementerCount, 1)
    }
}

// MARK: - Helpers

extension HOTPPreviewViewRepositoryImplTests {
    @MainActor
    private func makeSUT(
        timer: IntervalTimerMock = IntervalTimerMock(),
        store: VaultStoreHOTPIncrementerMock = VaultStoreHOTPIncrementerMock()
    ) -> HOTPPreviewViewRepositoryImpl {
        HOTPPreviewViewRepositoryImpl(timer: timer, store: store)
    }
}
