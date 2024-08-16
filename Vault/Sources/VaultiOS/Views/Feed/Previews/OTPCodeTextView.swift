import Combine
import SwiftUI
import VaultFeed

public struct OTPCodeTextView: View {
    var codeState: OTPCodeState
    var scaledDigitSpacing: Double = 8

    public var body: some View {
        switch codeState {
        case .notReady, .finished, .obfuscated:
            placeholderCode(digits: 6)
                .transition(.blurReplace(.downUp))
        case let .error(_, digits):
            placeholderCode(digits: digits)
                .foregroundColor(.red)
                .transition(.blurReplace(.downUp))
        case let .visible(code):
            makeCodeView(text: code)
                .transition(.blurReplace(.downUp))
        }
    }

    private func placeholderCode(digits: Int) -> some View {
        makeCodeView(text: String(repeating: "•", count: digits))
    }

    private func makeCodeView(text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: spacing) {
            ForEach(splitText(text: text)) { value in
                Text(value.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.1)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    private var spacing: Double {
        UIFontMetrics.default.scaledValue(for: scaledDigitSpacing)
    }

    private struct TextPart: Identifiable {
        let id = UUID()
        var text: String
    }

    private func splitText(text: String) -> [TextPart] {
        let chunkSize = chunkSize(length: text.count)
        let chunks = Array(text).chunked(by: chunkSize)
        return chunks.map { chunk in
            TextPart(text: chunk)
        }
    }

    private func chunkSize(length: Int) -> Int {
        switch length {
        case 0 ..< 6:
            length
        case let x where x.isMultiple(of: 3):
            3
        case let x where x.isMultiple(of: 4):
            4
        case let x where x.isMultiple(of: 5):
            5
        default:
            3
        }
    }
}

extension [Character] {
    fileprivate func chunked(by chunkSize: Int) -> [String] {
        stride(from: startIndex, to: endIndex, by: chunkSize).map {
            let startIndex = $0
            let endIndex = Swift.min($0 + chunkSize, count)
            let actual = Array(self[startIndex ..< endIndex])
            return String(actual)
        }
    }
}

struct CodeTextView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            OTPCodeTextView(
                codeState: .visible("123456")
            )

            OTPCodeTextView(
                codeState: .visible("1234567")
            )

            OTPCodeTextView(
                codeState: .visible("12345678")
            )

            OTPCodeTextView(
                codeState: .visible("123456789")
            )

            OTPCodeTextView(
                codeState: .visible("1234567890")
            )

            OTPCodeTextView(
                codeState: .finished
            )

            OTPCodeTextView(
                codeState: .error(.init(userTitle: "Any", debugDescription: "Any"), digits: 6)
            )
        }
        .font(.system(.largeTitle, design: .monospaced))
    }
}
