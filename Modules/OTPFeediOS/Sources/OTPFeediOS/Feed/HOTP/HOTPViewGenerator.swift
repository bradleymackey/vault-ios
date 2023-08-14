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
    let timer: LiveIntervalTimer
    var isEditing: Bool

    private struct CachedViewModels {
        var preview: CodePreviewViewModel
        var incrementer: CodeIncrementerViewModel<LiveIntervalTimer>
    }

    private var viewModelCache = [UUID: CachedViewModels]()

    public init(timer: LiveIntervalTimer, isEditing: Bool) {
        self.timer = timer
        self.isEditing = isEditing
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

    public func makeHOTPView(counter: UInt64, code: StoredOTPCode) -> some View {
        let viewModels = makeViewModelForCode(counter: counter, code: code)
        return HOTPCodePreviewView(
            buttonView: CodeButtonView(viewModel: viewModels.incrementer),
            previewViewModel: viewModels.preview,
            isEditing: isEditing
        )
    }
}
