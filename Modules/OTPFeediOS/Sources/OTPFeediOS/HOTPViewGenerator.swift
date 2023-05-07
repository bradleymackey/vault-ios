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
    var hideCodes: Bool
    public init(hideCodes: Bool) {
        self.hideCodes = hideCodes
    }

    public func makeHOTPView(counter: UInt64, code: OTPAuthCode) -> some View {
        let renderer = HOTPCodeRenderer(hotpGenerator: code.hotpGenerator(), initialCounter: counter)
        let previewViewModel = CodePreviewViewModel(
            accountName: code.accountName,
            issuer: code.issuer,
            renderer: renderer
        )
        let incrementerViewModel = CodeIncrementerViewModel(hotpRenderer: renderer, counter: counter)
        return HOTPCodePreviewView(
            buttonView: CodeButtonView(viewModel: incrementerViewModel),
            previewViewModel: previewViewModel,
            hideCode: hideCodes
        )
    }
}
