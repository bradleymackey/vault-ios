import CryptoEngine
import FoundationExtensions
import SwiftUI
import VaultCore
import VaultFeed

@MainActor
public final class HOTPPreviewViewGenerator<Factory: HOTPPreviewViewFactory>: VaultItemPreviewViewGenerator {
    public typealias PreviewItem = HOTPAuthCode

    let viewFactory: Factory
    let timer: any IntervalTimer

    private var rendererCache = Cache<UUID, HOTPCodeRenderer>()
    private var previewViewModelCache = Cache<UUID, OTPCodePreviewViewModel>()
    private var incrementerViewModelCache = Cache<UUID, OTPCodeIncrementerViewModel>()

    public init(viewFactory: Factory, timer: any IntervalTimer) {
        self.viewFactory = viewFactory
        self.timer = timer
    }

    public func makeVaultPreviewView(
        item: PreviewItem,
        metadata: StoredVaultItem.Metadata,
        behaviour: VaultItemViewBehaviour
    ) -> some View {
        viewFactory.makeHOTPView(
            viewModel: makePreviewViewModel(metadata: metadata, code: item),
            incrementer: makeIncrementerViewModel(id: metadata.id, code: item),
            behaviour: behaviour
        )
    }

    public func scenePhaseDidChange(to scene: ScenePhase) {
        if scene == .background {
            hideAllCodesUntilNextUpdate()
        }
    }

    public func didAppear() {
        // noop
    }
}

extension HOTPPreviewViewGenerator {
    public func hideAllCodesUntilNextUpdate() {
        for viewModel in previewViewModelCache.values {
            viewModel.hideCodeUntilNextUpdate()
        }
    }
}

extension HOTPPreviewViewGenerator: VaultItemPreviewActionHandler, VaultItemCopyActionHandler {
    public func previewActionForVaultItem(id: UUID) -> VaultItemPreviewAction? {
        guard let visibleCode = textToCopyForVaultItem(id: id) else { return nil }
        return .copyText(visibleCode)
    }

    public func textToCopyForVaultItem(id: UUID) -> String? {
        previewViewModelCache[id]?.code.visibleCode
    }
}

// MARK: - Caching

extension HOTPPreviewViewGenerator: VaultItemCache {
    public nonisolated func invalidateVaultItemDetailCache(forVaultItemWithID id: UUID) async {
        await MainActor.run {
            rendererCache.remove(key: id)
            previewViewModelCache.remove(key: id)
            incrementerViewModelCache.remove(key: id)
        }
    }

    var cachedViewsCount: Int {
        previewViewModelCache.count
    }

    var cachedRendererCount: Int {
        rendererCache.count
    }

    var cachedIncrementerCount: Int {
        incrementerViewModelCache.count
    }

    private func makeRenderer(id: UUID, code: HOTPAuthCode) -> HOTPCodeRenderer {
        rendererCache.getOrCreateValue(for: id) {
            HOTPCodeRenderer(hotpGenerator: code.data.hotpGenerator())
        }
    }

    private func makeIncrementerViewModel(id: UUID, code: HOTPAuthCode) -> OTPCodeIncrementerViewModel {
        incrementerViewModelCache.getOrCreateValue(for: id) {
            OTPCodeIncrementerViewModel(
                hotpRenderer: makeRenderer(id: id, code: code),
                timer: timer,
                initialCounter: code.counter
            )
        }
    }

    private func makePreviewViewModel(
        metadata: StoredVaultItem.Metadata,
        code: HOTPAuthCode
    ) -> OTPCodePreviewViewModel {
        previewViewModelCache.getOrCreateValue(for: metadata.id) {
            let viewModel = OTPCodePreviewViewModel(
                accountName: code.data.accountName,
                issuer: code.data.issuer,
                color: metadata.color ?? .default,
                renderer: makeRenderer(id: metadata.id, code: code)
            )
            viewModel.hideCodeUntilNextUpdate()
            return viewModel
        }
    }
}
