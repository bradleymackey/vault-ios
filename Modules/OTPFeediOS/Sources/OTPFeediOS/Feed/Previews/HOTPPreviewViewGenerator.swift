import CoreModels
import CryptoEngine
import OTPCore
import OTPFeed
import SwiftUI

@MainActor
public final class HOTPPreviewViewGenerator: ObservableObject, OTPViewGenerator {
    public typealias Code = HOTPAuthCode

    let timer: any IntervalTimer

    private var viewModelCache = Cache<UUID, CachedViewModels>()

    public init(timer: any IntervalTimer) {
        self.timer = timer
    }

    public func makeOTPView(id: UUID, code: Code, behaviour: OTPViewBehaviour?) -> some View {
        let viewModels = makeViewModelForCode(id: id, code: code)
        return HOTPCodePreviewView(
            buttonView: CodeButtonView(viewModel: viewModels.incrementer),
            previewViewModel: viewModels.preview,
            behaviour: behaviour
        )
    }

    /// Get the current visible code for a given generated code.
    public func currentCode(id: UUID) -> String? {
        guard let cached = viewModelCache[id] else { return nil }
        return cached.preview.code.visibleCode
    }

    public func hideAllCodesUntilNextUpdate() {
        for viewModel in viewModelCache.values {
            viewModel.preview.hideCodeUntilNextUpdate()
        }
    }
}

// MARK: - Caching

extension HOTPPreviewViewGenerator: CodeDetailCache {
    public func invalidateCache(id: UUID) {
        viewModelCache.remove(key: id)
    }

    private struct CachedViewModels {
        var preview: CodePreviewViewModel
        var incrementer: CodeIncrementerViewModel
    }

    private func makeViewModelForCode(
        id: UUID,
        code: HOTPAuthCode
    ) -> CachedViewModels {
        viewModelCache.get(key: id) {
            let renderer = HOTPCodeRenderer(hotpGenerator: code.data.hotpGenerator())
            let previewViewModel = CodePreviewViewModel(
                accountName: code.data.accountName,
                issuer: code.data.issuer,
                renderer: renderer
            )
            previewViewModel.hideCodeUntilNextUpdate()
            let incrementerViewModel = CodeIncrementerViewModel(
                hotpRenderer: renderer,
                timer: timer,
                initialCounter: code.counter
            )
            return CachedViewModels(preview: previewViewModel, incrementer: incrementerViewModel)
        }
    }
}
