import Combine
import Foundation
import OTPCore

@MainActor
public final class CodeDetailViewModel: ObservableObject {
    private let code: OTPAuthCode

    public init(code: OTPAuthCode) {
        self.code = code
    }

    public var menuItems: [CodeDetailMenuItem] {
        let details = CodeDetailMenuItem(id: "detail", title: "Details", entries: Self.makeInfoEntries(code))
        return [details]
    }
}

extension CodeDetailViewModel {
    private static func makeInfoEntries(_ code: OTPAuthCode) -> [DetailEntry] {
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
