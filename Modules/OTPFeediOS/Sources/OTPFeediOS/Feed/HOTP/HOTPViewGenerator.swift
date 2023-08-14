import CryptoEngine
import OTPCore
import OTPFeed
import SwiftUI

@MainActor
public protocol HOTPViewGenerator {
    associatedtype CodeView: View
    func makeHOTPView(counter: UInt64, code: StoredOTPCode) -> CodeView
}

@MainActor
public final class HOTPPreviewViewGenerator: HOTPViewGenerator {
    let timer: any IntervalTimer
    var isEditing: Bool

    private var viewModelCache = [UUID: CachedViewModels]()

    public init(timer: any IntervalTimer, isEditing: Bool) {
        self.timer = timer
        self.isEditing = isEditing
    }

    public func makeHOTPView(counter: UInt64, code: StoredOTPCode) -> some View {
        let viewModels = makeViewModelForCode(counter: counter, code: code)
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
        counter: UInt64,
        code: StoredOTPCode
    ) -> CachedViewModels {
        if let viewModel = viewModelCache[code.id] {
            return viewModel
        } else {
            let renderer = HOTPCodeRenderer(hotpGenerator: code.code.hotpGenerator())
            let previewViewModel = CodePreviewViewModel(
                accountName: code.code.accountName,
                issuer: code.code.issuer,
                renderer: renderer
            )
            previewViewModel.hideCodeUntilNextUpdate()
            let incrementerViewModel = CodeIncrementerViewModel(
                hotpRenderer: renderer,
                timer: timer,
                initialCounter: counter
            )
            let cached = CachedViewModels(preview: previewViewModel, incrementer: incrementerViewModel)
            viewModelCache[code.id] = cached
            return cached
        }
    }
}
