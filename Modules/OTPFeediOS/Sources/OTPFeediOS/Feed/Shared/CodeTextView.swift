import Combine
import OTPFeed
import SwiftUI

public struct CodeTextView: View {
    var codeState: OTPCodeState
    var scaledDigitSpacing: Double = 10

    public var body: some View {
        switch codeState {
        case .notReady, .finished, .editing:
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
            return length
        case let x where x.isMultiple(of: 3):
            return 3
        case let x where x.isMultiple(of: 4):
            return 4
        case let x where x.isMultiple(of: 5):
            return 5
        default:
            return 3
        }
    }
}

private extension [Character] {
    func chunked(by chunkSize: Int) -> [String] {
        stride(from: startIndex, to: endIndex, by: chunkSize).map {
            let startIndex = $0
            let endIndex = Swift.min($0 + chunkSize, count)
            let characters = endIndex - startIndex
            let paddingRequired = chunkSize - characters
            let actual = Array(self[startIndex ..< endIndex])
            let padding = Array(repeating: Character(" "), count: paddingRequired)
            return String(actual + padding)
        }
    }
}

struct CodeTextView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CodeTextView(
                codeState: .visible("123456")
            )

            CodeTextView(
                codeState: .visible("1234567")
            )

            CodeTextView(
                codeState: .visible("12345678")
            )

            CodeTextView(
                codeState: .visible("123456789")
            )

            CodeTextView(
                codeState: .visible("1234567890")
            )

            CodeTextView(
                codeState: .finished
            )

            CodeTextView(
                codeState: .error(.init(userTitle: "Any", debugDescription: "Any"), digits: 6)
            )
        }
        .font(.system(.largeTitle, design: .monospaced))
    }
}
