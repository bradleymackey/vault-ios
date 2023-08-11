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
public struct HOTPPreviewViewGenerator: HOTPViewGenerator {
    let timer: LiveIntervalTimer
    var isEditing: Bool

    public init(timer: LiveIntervalTimer, isEditing: Bool) {
        self.timer = timer
        self.isEditing = isEditing
    }

    public func makeHOTPView(counter: UInt64, code: StoredOTPCode) -> some View {
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
        return HOTPCodePreviewView(
            buttonView: CodeButtonView(viewModel: incrementerViewModel),
            previewViewModel: previewViewModel,
            isEditing: isEditing
        )
    }
}
