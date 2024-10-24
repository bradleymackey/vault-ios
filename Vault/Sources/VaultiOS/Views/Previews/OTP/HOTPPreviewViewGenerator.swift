import CryptoEngine
import SwiftUI
import VaultFeed

@MainActor
final class HOTPPreviewViewGenerator<Factory: HOTPPreviewViewFactory>: VaultItemPreviewViewGenerator {
    typealias PreviewItem = HOTPAuthCode

    private let viewFactory: Factory
    private let timer: any IntervalTimer
    private let store: any VaultStoreHOTPIncrementer

    private var codePublisherCache = Cache<Identifier<VaultItem>, HOTPCodePublisher>()
    private var previewViewModelCache = Cache<Identifier<VaultItem>, OTPCodePreviewViewModel>()
    private var incrementerViewModelCache = Cache<Identifier<VaultItem>, OTPCodeIncrementerViewModel>()

    init(viewFactory: Factory, timer: any IntervalTimer, store: any VaultStoreHOTPIncrementer) {
        self.viewFactory = viewFactory
        self.timer = timer
        self.store = store
    }

    func makeVaultPreviewView(
        item: PreviewItem,
        metadata: VaultItem.Metadata,
        behaviour: VaultItemViewBehaviour
    ) -> some View {
        viewFactory.makeHOTPView(
            viewModel: makePreviewViewModel(metadata: metadata, code: item),
            incrementer: makeIncrementerViewModel(id: metadata.id, code: item),
            behaviour: behaviour
        )
    }

    func scenePhaseDidChange(to scene: ScenePhase) {
        if scene == .background {
            markAllCodesAsExpired()
        }
    }

    func didAppear() {
        // noop
    }
}

extension HOTPPreviewViewGenerator {
    func markAllCodesAsExpired() {
        for viewModel in previewViewModelCache.values {
            viewModel.codeExpired()
        }
    }
}

extension HOTPPreviewViewGenerator: VaultItemPreviewActionHandler, VaultItemCopyActionHandler {
    func previewActionForVaultItem(id: Identifier<VaultItem>) -> VaultItemPreviewAction? {
        guard let visibleCode = textToCopyForVaultItem(id: id) else { return nil }
        return .copyText(visibleCode)
    }

    func textToCopyForVaultItem(id: Identifier<VaultItem>) -> String? {
        previewViewModelCache[id]?.code.visibleCode
    }
}

// MARK: - Caching

extension HOTPPreviewViewGenerator: VaultItemCache {
    nonisolated func invalidateVaultItemDetailCache(forVaultItemWithID id: Identifier<VaultItem>) async {
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

    private func makeCodePublisher(id: Identifier<VaultItem>, code: HOTPAuthCode) -> HOTPCodePublisher {
        codePublisherCache.getOrCreateValue(for: id) {
            HOTPCodePublisher(hotpGenerator: code.data.hotpGenerator())
        }
    }

    private func makeIncrementerViewModel(
        id: Identifier<VaultItem>,
        code: HOTPAuthCode
    ) -> OTPCodeIncrementerViewModel {
        incrementerViewModelCache.getOrCreateValue(for: id) {
            OTPCodeIncrementerViewModel(
                id: id,
                codePublisher: makeCodePublisher(id: id, code: code),
                timer: timer,
                initialCounter: code.counter,
                incrementerStore: store
            )
        }
    }

    private func makePreviewViewModel(
        metadata: VaultItem.Metadata,
        code: HOTPAuthCode
    ) -> OTPCodePreviewViewModel {
        previewViewModelCache.getOrCreateValue(for: metadata.id) {
            let viewModel = OTPCodePreviewViewModel(
                accountName: code.data.accountName,
                issuer: code.data.issuer,
                color: metadata.color ?? .default,
                codePublisher: makeCodePublisher(id: metadata.id, code: code)
            )
            viewModel.codeExpired()
            return viewModel
        }
    }
}
