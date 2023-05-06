import CryptoEngine
import OTPCore
import OTPFeed
import SwiftUI

@MainActor
public protocol HOTPViewGenerator {
    associatedtype CodeView: View
    func makeHOTPView(counter: UInt64, code: OTPAuthCode) -> CodeView
}

@MainActor
public struct LiveHOTPPreviewViewGenerator: HOTPViewGenerator {
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

@MainActor
public struct LiveHOTPItemViewDecorator<Generator: HOTPViewGenerator>: HOTPViewGenerator {
    let generator: Generator
    let onDetailTap: (OTPAuthCode) -> Void

    public init(generator: Generator, onDetailTap: @escaping (OTPAuthCode) -> Void) {
        self.generator = generator
        self.onDetailTap = onDetailTap
    }

    public func makeHOTPView(counter: UInt64, code: OTPAuthCode) -> some View {
        let baseView = generator.makeHOTPView(counter: counter, code: code)
        return OTPFeedItemView(preview: baseView, buttonPadding: 8) {
            onDetailTap(code)
        }
    }
}
