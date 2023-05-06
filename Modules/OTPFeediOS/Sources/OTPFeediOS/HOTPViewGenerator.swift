import CryptoEngine
import OTPCore
import OTPFeed
import SwiftUI

public protocol HOTPViewGenerator {
    associatedtype CodeView: View
    func makeHOTPView(counter: UInt64, code: OTPAuthCode) -> CodeView
}

public struct LiveHOTPViewGenerator: HOTPViewGenerator {
    public init() {}

    public func makeHOTPView(counter: UInt64, code: OTPAuthCode) -> some View {
        let renderer = HOTPCodeRenderer(hotpGenerator: code.hotpGenerator(), initialCounter: counter)
        let previewViewModel = CodePreviewViewModel(renderer: renderer)
        let incrementerViewModel = CodeIncrementerViewModel(hotpRenderer: renderer, counter: counter)
        return HOTPCodePreviewView(
            accountName: code.accountName,
            issuer: code.issuer,
            textView: CodeTextView(viewModel: previewViewModel, codeSpacing: 10.0),
            buttonView: CodeButtonView(viewModel: incrementerViewModel),
            previewViewModel: previewViewModel
        )
    }
}
