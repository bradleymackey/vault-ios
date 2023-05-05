import CryptoEngine
import OTPCore
import OTPFeed
import SwiftUI

public protocol HOTPViewGenerator {
    associatedtype CodeView: View
    func makeHOTPView(counter: UInt32, code: OTPAuthCode) -> CodeView
}

public struct LiveHOTPViewGenerator: HOTPViewGenerator {
    public init() {}

    public func makeHOTPView(counter: UInt32, code: OTPAuthCode) -> some View {
        let renderer = HOTPCodeRenderer(hotpGenerator: code.hotpGenerator(), initialCounter: UInt64(counter))
        let previewViewModel = CodePreviewViewModel(renderer: renderer)
        let incrementerViewModel = CodeIncrementerViewModel(hotpRenderer: renderer, counter: UInt64(counter))
        return HOTPCodePreviewView(
            accountName: code.accountName,
            issuer: code.issuer,
            textView: CodeTextView(viewModel: previewViewModel, codeSpacing: 10.0),
            buttonView: CodeButtonView(viewModel: incrementerViewModel),
            previewViewModel: previewViewModel
        )
    }
}
