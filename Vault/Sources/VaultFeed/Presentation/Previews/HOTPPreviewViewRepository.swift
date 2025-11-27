import Foundation
import FoundationExtensions
import VaultCore

/// Canonical store for rendering HOTP previews.
///
/// This should be used for fetching and externally updating the state of view models so we have a source of truth
/// for information relating to the view model such as: cache state, visibility & expiry state.
///
/// @mockable
@MainActor
public protocol HOTPPreviewViewRepository: VaultItemCache, VaultItemCopyActionHandler {
    func previewViewModel(metadata: VaultItem.Metadata, code: HOTPAuthCode) -> OTPCodePreviewViewModel
    func incrementerViewModel(id: Identifier<VaultItem>, code: HOTPAuthCode) -> OTPCodeIncrementerViewModel
    func expireAll()
    func obfuscateForPrivacy()
    func unobfuscateForPrivacy()
}

public final class HOTPPreviewViewRepositoryImpl: HOTPPreviewViewRepository {
    private let timer: any IntervalTimer
    private let store: any VaultStoreHOTPIncrementer
    private var codePublisherCache = Cache<Identifier<VaultItem>, HOTPCodePublisher>()
    private var previewViewModelCache = Cache<Identifier<VaultItem>, OTPCodePreviewViewModel>()
    private var incrementerViewModelCache = Cache<Identifier<VaultItem>, OTPCodeIncrementerViewModel>()

    public init(timer: any IntervalTimer, store: any VaultStoreHOTPIncrementer) {
        self.timer = timer
        self.store = store
    }

    public func previewViewModel(metadata: VaultItem.Metadata, code: HOTPAuthCode) -> OTPCodePreviewViewModel {
        previewViewModelCache.getOrCreateValue(for: metadata.id) {
            let viewModel = OTPCodePreviewViewModel(
                accountName: code.data.accountName,
                issuer: code.data.issuer,
                color: metadata.color ?? .default,
                isLocked: metadata.lockState.isLocked,
                codePublisher: makeCodePublisher(id: metadata.id, code: code),
            )
            viewModel.update(.obfuscated(.expiry))
            return viewModel
        }
    }

    public func incrementerViewModel(id: Identifier<VaultItem>, code: HOTPAuthCode) -> OTPCodeIncrementerViewModel {
        incrementerViewModelCache.getOrCreateValue(for: id) {
            OTPCodeIncrementerViewModel(
                id: id,
                codePublisher: makeCodePublisher(id: id, code: code),
                timer: timer,
                initialCounter: code.counter,
                incrementerStore: store,
            )
        }
    }

    public func expireAll() {
        for viewModel in previewViewModelCache.values {
            viewModel.update(.obfuscated(.expiry))
        }
    }

    public func obfuscateForPrivacy() {
        for viewModel in previewViewModelCache.values {
            viewModel.update(.obfuscated(.privacy))
        }
    }

    public func unobfuscateForPrivacy() {
        for viewModel in previewViewModelCache.values {
            viewModel.updateRemovePrivacyObfuscation()
        }
    }
}

// MARK: - Builders

extension HOTPPreviewViewRepositoryImpl {
    private func makeCodePublisher(id: Identifier<VaultItem>, code: HOTPAuthCode) -> HOTPCodePublisher {
        codePublisherCache.getOrCreateValue(for: id) {
            HOTPCodePublisher(hotpGenerator: code.data.hotpGenerator())
        }
    }
}

// MARK: - Conformances

extension HOTPPreviewViewRepositoryImpl: VaultItemCopyActionHandler {
    public func textToCopyForVaultItem(id: Identifier<VaultItem>) -> VaultTextCopyAction? {
        previewViewModelCache[id]?.pasteboardCopyText
    }
}

extension HOTPPreviewViewRepositoryImpl: VaultItemCache {
    public nonisolated func vaultItemCacheClearAll() async {
        await MainActor.run {
            codePublisherCache.removeAll()
            previewViewModelCache.removeAll()
            incrementerViewModelCache.removeAll()
        }
    }

    public nonisolated func vaultItemCacheClear(forVaultItemWithID id: Identifier<VaultItem>) async {
        await MainActor.run {
            codePublisherCache.remove(key: id)
            previewViewModelCache.remove(key: id)
            incrementerViewModelCache.remove(key: id)
        }
    }

    var cachedViewsCount: Int {
        previewViewModelCache.count
    }

    var cachedRendererCount: Int {
        codePublisherCache.count
    }

    var cachedIncrementerCount: Int {
        incrementerViewModelCache.count
    }
}
