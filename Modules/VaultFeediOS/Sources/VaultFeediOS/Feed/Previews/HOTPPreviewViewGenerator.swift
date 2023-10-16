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
    private var previewViewModelCache = Cache<UUID, CodePreviewViewModel>()
    private var incrementerViewModelCache = Cache<UUID, CodeIncrementerViewModel>()

    public init(viewFactory: Factory, timer: any IntervalTimer) {
        self.viewFactory = viewFactory
        self.timer = timer
    }

    public func makeVaultPreviewView(id: UUID, item: PreviewItem, behaviour: VaultItemViewBehaviour) -> some View {
        viewFactory.makeHOTPView(
            viewModel: makePreviewViewModel(id: id, code: item),
            incrementer: makeIncrementerViewModel(id: id, code: item),
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

public extension HOTPPreviewViewGenerator {
    func hideAllCodesUntilNextUpdate() {
        for viewModel in previewViewModelCache.values {
            viewModel.hideCodeUntilNextUpdate()
        }
    }
}

extension HOTPPreviewViewGenerator: VaultItemCopyTextProvider {
    public func currentCopyableText(id: UUID) -> String? {
        guard let cached = previewViewModelCache[id] else { return nil }
        return cached.code.visibleCode
    }
}

// MARK: - Caching

extension HOTPPreviewViewGenerator: VaultItemCache {
    public func invalidateVaultItemDetailCache(forVaultItemWithID id: UUID) {
        rendererCache.remove(key: id)
        previewViewModelCache.remove(key: id)
        incrementerViewModelCache.remove(key: id)
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

    private func makeIncrementerViewModel(id: UUID, code: HOTPAuthCode) -> CodeIncrementerViewModel {
        incrementerViewModelCache.getOrCreateValue(for: id) {
            CodeIncrementerViewModel(
                hotpRenderer: makeRenderer(id: id, code: code),
                timer: timer,
                initialCounter: code.counter
            )
        }
    }

    private func makePreviewViewModel(id: UUID, code: HOTPAuthCode) -> CodePreviewViewModel {
        previewViewModelCache.getOrCreateValue(for: id) {
            let viewModel = CodePreviewViewModel(
                accountName: code.data.accountName,
                issuer: code.data.issuer,
                renderer: makeRenderer(id: id, code: code)
            )
            viewModel.hideCodeUntilNextUpdate()
            return viewModel
        }
    }
}
