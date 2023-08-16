import CryptoEngine
import OTPCore
import OTPFeed
import SwiftUI

@MainActor
public final class HOTPPreviewViewGenerator: ObservableObject, OTPViewGenerator {
    public typealias Code = HOTPAuthCode

    let timer: any IntervalTimer

    private var viewModelCache = [UUID: CachedViewModels]()

    public init(timer: any IntervalTimer) {
        self.timer = timer
    }

    public func makeOTPView(id: UUID, code: Code, isEditing: Bool) -> some View {
        let viewModels = makeViewModelForCode(id: id, code: code)
        return HOTPCodePreviewView(
            buttonView: CodeButtonView(viewModel: viewModels.incrementer),
            previewViewModel: viewModels.preview,
            isEditing: isEditing
        )
    }

    /// Get the current visible code for a given generated code.
    public func currentCode(id: UUID) -> String? {
        guard let cached = viewModelCache[id] else { return nil }
        return cached.preview.code.visibleCode
    }
}

// MARK: - Caching

extension HOTPPreviewViewGenerator {
    private struct CachedViewModels {
        var preview: CodePreviewViewModel
        var incrementer: CodeIncrementerViewModel
    }

    private func makeViewModelForCode(
        id: UUID,
        code: HOTPAuthCode
    ) -> CachedViewModels {
        if let viewModel = viewModelCache[id] {
            return viewModel
        } else {
            let renderer = HOTPCodeRenderer(hotpGenerator: code.hotpGenerator())
            let previewViewModel = CodePreviewViewModel(
                accountName: code.accountName,
                issuer: code.issuer,
                renderer: renderer
            )
            previewViewModel.hideCodeUntilNextUpdate()
            let incrementerViewModel = CodeIncrementerViewModel(
                hotpRenderer: renderer,
                timer: timer,
                initialCounter: code.counter
            )
            let cached = CachedViewModels(preview: previewViewModel, incrementer: incrementerViewModel)
            viewModelCache[id] = cached
            return cached
        }
    }
}
