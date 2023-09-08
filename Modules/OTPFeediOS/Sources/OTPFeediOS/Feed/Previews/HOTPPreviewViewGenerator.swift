import CoreModels
import CryptoEngine
import OTPCore
import OTPFeed
import SwiftUI

@MainActor
public final class HOTPPreviewViewGenerator<Factory: HOTPPreviewViewFactory>: ObservableObject, OTPViewGenerator {
    public typealias Code = HOTPAuthCode

    let viewFactory: Factory
    let timer: any IntervalTimer

    private var rendererCache = Cache<UUID, HOTPCodeRenderer>()
    private var previewViewModelCache = Cache<UUID, CodePreviewViewModel>()
    private var incrementerViewModelCache = Cache<UUID, CodeIncrementerViewModel>()

    public init(viewFactory: Factory, timer: any IntervalTimer) {
        self.viewFactory = viewFactory
        self.timer = timer
    }

    public func makeOTPView(id: UUID, code: Code, behaviour: OTPViewBehaviour) -> some View {
        viewFactory.makeHOTPView(
            viewModel: makePreviewViewModel(id: id, code: code),
            incrementer: makeIncrementerViewModel(id: id, code: code),
            behaviour: behaviour
        )
    }

    /// Get the current visible code for a given generated code.
    public func currentCode(id: UUID) -> String? {
        guard let cached = previewViewModelCache[id] else { return nil }
        return cached.code.visibleCode
    }

    public func hideAllCodesUntilNextUpdate() {
        for viewModel in previewViewModelCache.values {
            viewModel.hideCodeUntilNextUpdate()
        }
    }
}

// MARK: - Caching

extension HOTPPreviewViewGenerator: CodeDetailCache {
    public func invalidateCache(id: UUID) {
        rendererCache.remove(key: id)
        previewViewModelCache.remove(key: id)
        incrementerViewModelCache.remove(key: id)
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
