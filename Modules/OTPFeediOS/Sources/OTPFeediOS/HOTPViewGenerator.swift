import CryptoEngine
import OTPCore
import OTPFeed
import SwiftUI

public protocol HOTPViewGenerator {
    associatedtype CodeView: View
    func makeHOTPView(counter: UInt32, code: OTPAuthCode) -> CodeView
}

public struct LiveHOTPViewGenerator: HOTPViewGenerator {
    init() {}

    public func makeHOTPView(counter: UInt32, code: OTPAuthCode) -> some View {
        let renderer = HOTPCodeRenderer(hotpGenerator: code.hotpGenerator(), initialCounter: UInt64(counter))
//        let previewViewModel = CodePreviewViewModel(renderer: renderer)
        return Text("Code needs rendering")
    }
}
