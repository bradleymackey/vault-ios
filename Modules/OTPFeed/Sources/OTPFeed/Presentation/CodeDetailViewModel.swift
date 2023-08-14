import Combine
import Foundation
import OTPCore

@MainActor
public final class CodeDetailViewModel: ObservableObject {
    private let storedCode: StoredOTPCode

    public init(storedCode: StoredOTPCode) {
        self.storedCode = storedCode
    }

    public var detailMenuItems: [CodeDetailMenuItem] {
        let details = CodeDetailMenuItem(
            id: "detail",
            title: localized(key: "codeDetail.listSection.details.title"),
            systemIconName: "books.vertical.fill",
            entries: Self.makeInfoEntries(storedCode.code)
        )
        return [details]
    }

    public var createdDateTitle: String {
        localized(key: "codeDetail.listSection.created.title")
    }

    public var createdDateValue: String {
        storedCode.created.formatted(date: .abbreviated, time: .omitted)
    }

    public var updatedDateTitle: String {
        localized(key: "codeDetail.listSection.updated.title")
    }

    public var updatedDateValue: String {
        storedCode.updated.formatted(date: .abbreviated, time: .omitted)
    }
}

extension CodeDetailViewModel {
    private static func makeInfoEntries(_ code: GenericOTPAuthCode) -> [DetailEntry] {
        let formatter = CodeDetailFormatter(code: code)
        var entries = [DetailEntry]()
        entries.append(
            DetailEntry(
                title: localized(key: "codeDetail.listSection.type.title"),
                detail: formatter.typeName,
                systemIconName: "tag.fill"
            )
        )
        if let period = formatter.period {
            entries.append(
                DetailEntry(
                    title: localized(key: "codeDetail.listSection.period.title"),
                    detail: period,
                    systemIconName: "clock.fill"
                )
            )
        }
        entries.append(
            DetailEntry(
                title: localized(key: "codeDetail.listSection.digits.title"),
                detail: formatter.digits,
                systemIconName: "number"
            )
        )
        entries.append(
            DetailEntry(
                title: localized(key: "codeDetail.listSection.algorithm.title"),
                detail: formatter.algorithm,
                systemIconName: "lock.laptopcomputer"
            )
        )
        entries.append(
            DetailEntry(
                title: localized(key: "codeDetail.listSection.secretFormat.title"),
                detail: formatter.secretType,
                systemIconName: "lock.fill"
            )
        )
        return entries
    }
}
