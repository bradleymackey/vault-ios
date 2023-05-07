import Combine
import OTPFeed
import SwiftUI

public struct CodeTextView: View {
    var codeState: OTPCodeState
    var codeSpacing: Double

    public var body: some View {
        switch codeState {
        case .notReady, .finished:
            placeholderCode(digits: 6)
        case let .error(_, digits):
            placeholderCode(digits: digits)
                .foregroundColor(.red)
        case let .visible(code):
            makeCodeView(text: code)
        }
    }

    private func placeholderCode(digits: Int) -> some View {
        makeCodeView(text: String(repeating: "0", count: digits))
            .redacted(reason: .placeholder)
    }

    private func makeCodeView(text: String) -> some View {
        OTPCodeText(text: text, spacing: codeSpacing)
    }
}

struct CodeTextView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CodeTextView(
                codeState: .visible("123456"),
                codeSpacing: 10
            )

            CodeTextView(
                codeState: .finished,
                codeSpacing: 10
            )

            CodeTextView(
                codeState: .error(.init(userTitle: "Any", debugDescription: "Any"), digits: 6),
                codeSpacing: 10
            )
        }
        .font(.system(.largeTitle, design: .monospaced))
    }
}
