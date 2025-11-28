import Foundation
import TestHelpers
import Testing
@testable import VaultFeed

@MainActor
struct HOTPPreviewViewRepositoryImplTests {
    @Test
    func initHasNoSideEffects() {
        let store = VaultStoreHOTPIncrementerMock()
        let sut = makeSUT(store: store)

        #expect(store.incrementCounterCallCount == 0)
        #expect(sut.cachedViewsCount == 0)
        #expect(sut.cachedRendererCount == 0)
        #expect(sut.cachedIncrementerCount == 0)
    }

    @Test
    func previewViewModelInitiallyExpired() {
        let sut = makeSUT()

        let viewModel = sut.previewViewModel(metadata: anyVaultItemMetadata(), code: anyHOTPCode())

        #expect(viewModel.code == .obfuscated(.expiry))
    }

    @Test
    func previewViewModelReturnsSameViewModelInstanceUsedCachedViewModels() {
        let sut = makeSUT()

        let sharedID = Identifier<VaultItem>.new()
        let viewModel1 = sut.previewViewModel(metadata: anyVaultItemMetadata(id: sharedID), code: anyHOTPCode())
        #expect(sut.cachedViewsCount == 1)
        let viewModel2 = sut.previewViewModel(metadata: anyVaultItemMetadata(id: sharedID), code: anyHOTPCode())
        #expect(sut.cachedViewsCount == 1)
        let viewModel3 = sut.previewViewModel(metadata: anyVaultItemMetadata(id: .new()), code: anyHOTPCode())
        #expect(sut.cachedViewsCount == 2)

        #expect(viewModel1 === viewModel2)
        #expect(viewModel1 !== viewModel3, "View Model 3 has a different ID")
        #expect(viewModel2 !== viewModel3, "View Model 3 has a different ID")
    }

    @Test
    func previewViewModelReturnsSameIncrementerInstanceUsedCachedViewModels() {
        let sut = makeSUT()

        let sharedID = Identifier<VaultItem>.new()
        let incrementer1 = sut.incrementerViewModel(id: sharedID, code: anyHOTPCode())
        #expect(sut.cachedIncrementerCount == 1)
        let incrementer2 = sut.incrementerViewModel(id: sharedID, code: anyHOTPCode())
        #expect(sut.cachedIncrementerCount == 1)
        let incrementer3 = sut.incrementerViewModel(id: .new(), code: anyHOTPCode())
        #expect(sut.cachedIncrementerCount == 2)

        #expect(incrementer1 === incrementer2)
        #expect(incrementer1 !== incrementer3, "View Model 3 has a different ID")
        #expect(incrementer2 !== incrementer3, "View Model 3 has a different ID")
    }

    @Test
    func textToCopyForVaultItemIsNilIfCacheEmpty() {
        let sut = makeSUT()

        let copyAction = sut.textToCopyForVaultItem(id: .new())

        #expect(copyAction == nil)
    }

    @Test
    func textToCopyForVaultItemIsNilWhenCodeIsObfuscated() {
        let sut = makeSUT()

        let id = Identifier<VaultItem>()
        _ = sut.previewViewModel(metadata: anyVaultItemMetadata(id: id), code: anyHOTPCode())
        let code = sut.textToCopyForVaultItem(id: id)

        #expect(code == nil, "Code is initially obfuscated, so this should be nil")
    }

    @Test
    func textToCopyForVaultItemIsCopyTextIfCodeHasBeenGenerated() {
        let sut = makeSUT()
        let id = Identifier<VaultItem>()
        let viewModel = sut.previewViewModel(metadata: anyVaultItemMetadata(id: id), code: anyHOTPCode())
        viewModel.update(.visible("123456"))

        let code = sut.textToCopyForVaultItem(id: id)

        #expect(code == .init(text: "123456", requiresAuthenticationToCopy: false))
    }

    @Test
    func textToCopyForVaultItemRequiresAuthenticationToCopyIfLocked() {
        let sut = makeSUT()
        let id = Identifier<VaultItem>()
        let viewModel = sut.previewViewModel(metadata: anyVaultItemMetadata(id: id), code: anyHOTPCode())
        viewModel.update(.locked(code: "123456"))

        let code = sut.textToCopyForVaultItem(id: id)

        #expect(code == .init(text: "123456", requiresAuthenticationToCopy: true))
    }

    @Test
    func expireAllMarksAllCachedViewsAsExpired() {
        let sut = makeSUT()
        let viewModel = sut.previewViewModel(metadata: anyVaultItemMetadata(), code: anyHOTPCode())

        viewModel.update(.visible("123456"))

        sut.expireAll()

        #expect(viewModel.code == .obfuscated(.expiry))
    }

    @Test
    func obfuscateForPrivacyObfuscatesVisibleCodesForPrivacy() {
        let sut = makeSUT()
        let viewModel = sut.previewViewModel(metadata: anyVaultItemMetadata(), code: anyHOTPCode())

        viewModel.update(.visible("123456"))

        sut.obfuscateForPrivacy()

        #expect(viewModel.code == .obfuscated(.privacy))
    }

    @Test
    func unobfuscateForPrivacyUnobfuscatesCodesHiddenForPrivacy() {
        let sut = makeSUT()
        let viewModel = sut.previewViewModel(metadata: anyVaultItemMetadata(), code: anyHOTPCode())

        viewModel.update(.visible("123456"))
        viewModel.update(.obfuscated(.privacy))

        sut.unobfuscateForPrivacy()

        #expect(viewModel.code == .visible("123456"))
    }

    @Test
    func vaultItemCacheClearRemovesItemsMatchingIDFromCache() async {
        let sut = makeSUT()

        let id1 = Identifier<VaultItem>()
        let id2 = Identifier<VaultItem>()

        _ = sut.previewViewModel(metadata: anyVaultItemMetadata(id: id1), code: anyHOTPCode())
        _ = sut.previewViewModel(metadata: anyVaultItemMetadata(id: id2), code: anyHOTPCode())
        _ = sut.incrementerViewModel(id: id1, code: anyHOTPCode())
        _ = sut.incrementerViewModel(id: id2, code: anyHOTPCode())

        #expect(sut.cachedViewsCount == 2)
        #expect(sut.cachedRendererCount == 2)
        #expect(sut.cachedIncrementerCount == 2)

        await sut.vaultItemCacheClear(forVaultItemWithID: id1)

        #expect(sut.cachedViewsCount == 1)
        #expect(sut.cachedRendererCount == 1)
        #expect(sut.cachedIncrementerCount == 1)
    }

    @Test
    func vaultItemCacheClearAllRemovesItemsMatchingIDFromCache() async {
        let sut = makeSUT()

        let id1 = Identifier<VaultItem>()
        let id2 = Identifier<VaultItem>()
        _ = sut.previewViewModel(metadata: anyVaultItemMetadata(id: id1), code: anyHOTPCode())
        _ = sut.previewViewModel(metadata: anyVaultItemMetadata(id: id2), code: anyHOTPCode())
        _ = sut.incrementerViewModel(id: id1, code: anyHOTPCode())
        _ = sut.incrementerViewModel(id: id2, code: anyHOTPCode())

        #expect(sut.cachedViewsCount == 2)
        #expect(sut.cachedRendererCount == 2)
        #expect(sut.cachedIncrementerCount == 2)

        await sut.vaultItemCacheClearAll()

        #expect(sut.cachedViewsCount == 0)
        #expect(sut.cachedRendererCount == 0)
        #expect(sut.cachedIncrementerCount == 0)
    }
}

// MARK: - Helpers

extension HOTPPreviewViewRepositoryImplTests {
    private func makeSUT(
        timer: IntervalTimerMock = IntervalTimerMock(),
        store: VaultStoreHOTPIncrementerMock = VaultStoreHOTPIncrementerMock(),
    ) -> HOTPPreviewViewRepositoryImpl {
        HOTPPreviewViewRepositoryImpl(timer: timer, store: store)
    }
}
