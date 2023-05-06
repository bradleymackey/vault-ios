import Combine
import Foundation
import OTPCore

public final class CodeDetailViewModel: ObservableObject {
    private let code: OTPAuthCode
    /// Detail entries about the code, in order, ready for presentation.
    public let entries: [DetailEntry]

    public init(code: OTPAuthCode) {
        self.code = code
        entries = Self.makeEntries(code)
    }
}

extension CodeDetailViewModel {
    private static func makeEntries(_ code: OTPAuthCode) -> [DetailEntry] {
        let formatter = CodeDetailFormatter(code: code)
        var entries = [DetailEntry]()
        entries.append(
            DetailEntry(title: "Type", detail: formatter.typeName)
        )
        if let period = formatter.period {
            entries.append(
                DetailEntry(title: "Period", detail: period)
            )
        }
        entries.append(
            DetailEntry(title: "Digits", detail: formatter.digits)
        )
        entries.append(
            DetailEntry(title: "Algorithm", detail: formatter.algorithm)
        )
        entries.append(
            DetailEntry(title: "Secret Format", detail: formatter.secretType)
        )
        return entries
    }
}
