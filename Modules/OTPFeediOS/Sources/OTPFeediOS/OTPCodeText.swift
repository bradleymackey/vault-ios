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
            TextPart(text: String(chunk))
        }
    }
}

private extension Array {
    func chunked(by chunkSize: Int) -> [[Element]] {
        stride(from: 0, to: count, by: chunkSize).map {
            Array(self[$0 ..< Swift.min($0 + chunkSize, count)])
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

            OTPCodeText(text: "123456789", spacing: 10)
                .font(.system(.title, design: .monospaced))
                .fontWeight(.bold)
                .frame(width: 50)
        }
    }
}
