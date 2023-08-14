import CryptoEngine
import OTPCore
import OTPFeed
import SwiftUI

@MainActor
public final class HOTPPreviewViewGenerator: ObservableObject, OTPViewGenerator {
    public typealias Code = HOTPAuthCode

    let timer: any IntervalTimer
    var isEditing: Bool

    private var viewModelCache = [UUID: CachedViewModels]()

    public init(timer: any IntervalTimer, isEditing: Bool) {
        self.timer = timer
        self.isEditing = isEditing
    }

    public func makeOTPView(id: UUID, code: Code) -> some View {
        let viewModels = makeViewModelForCode(id: id, code: code)
        return HOTPCodePreviewView(
            buttonView: CodeButtonView(viewModel: viewModels.incrementer),
            previewViewModel: viewModels.preview,
            isEditing: isEditing
        )
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
