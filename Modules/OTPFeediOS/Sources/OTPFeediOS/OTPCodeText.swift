import SwiftUI

/// Label that splits up characters into groups, appropriate for viewing an OTP.
struct OTPCodeText: View {
    var text: String
    var spacing: Double
    var chunkSize: Int = 3

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: spacing) {
            ForEach(splitText) { value in
                Text(value.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.1)
            }
        }
    }

    private struct TextPart: Identifiable {
        let id = UUID()
        var text: String
    }

    private var splitText: [TextPart] {
        let chunks = Array(text).chunked(by: chunkSize)
        return chunks.map { chunk in
            TextPart(text: chunk)
        }
    }
}

private extension [Character] {
    func chunked(by chunkSize: Int) -> [String] {
        stride(from: 0, to: count, by: chunkSize).map {
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

struct OTPCodeText_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            OTPCodeText(text: "123", spacing: 10)
                .font(.system(.title, design: .monospaced))
            OTPCodeText(text: "1234", spacing: 10)
                .font(.system(.title2, design: .monospaced))
            OTPCodeText(text: "123456", spacing: 3)
                .font(.system(.title2, design: .monospaced))
            OTPCodeText(text: "123456789", spacing: 10)
                .font(.system(.title, design: .monospaced))

            OTPCodeText(text: "12345678", spacing: 10)
                .font(.system(.largeTitle, design: .monospaced))
                .fontWeight(.bold)
                .frame(width: 100)
        }
    }
}
