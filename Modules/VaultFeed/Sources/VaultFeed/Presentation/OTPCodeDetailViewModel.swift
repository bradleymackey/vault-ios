import Combine
import Foundation
import VaultCore

@MainActor
@Observable
public final class OTPCodeDetailViewModel {
    public let storedCode: OTPAuthCode
    public let storedMetdata: StoredVaultItem.Metadata
    public var editingModel: OTPCodeDetailEditingModel

    public private(set) var isSaving = false
    public private(set) var isInEditMode = false

    private let editor: any OTPCodeDetailEditor
    private let didEncounterErrorSubject = PassthroughSubject<Error, Never>()
    private let isFinishedSubject = PassthroughSubject<Void, Never>()

    public init(
        storedCode: OTPAuthCode,
        storedMetadata: StoredVaultItem.Metadata,
        editor: any OTPCodeDetailEditor
    ) {
        self.storedCode = storedCode
        storedMetdata = storedMetadata
        self.editor = editor
        editingModel = OTPCodeDetailEditingModel(detail: .init(
            issuerTitle: storedCode.data.issuer ?? "",
            accountNameTitle: storedCode.data.accountName,
            description: storedMetadata.userDescription ?? ""
        ))
    }

    public var detailMenuItems: [OTPCodeDetailMenuItem] {
        let details = OTPCodeDetailMenuItem(
            id: "detail",
            title: localized(key: "codeDetail.listSection.details.title"),
            systemIconName: "books.vertical.fill",
            entries: Self.makeInfoEntries(storedCode)
        )
        return [details]
    }

    public func didEncounterErrorPublisher() -> AnyPublisher<Error, Never> {
        didEncounterErrorSubject.eraseToAnyPublisher()
    }

    /// Publishes when we are done looking at a given code, and should dismiss.
    public func isFinishedPublisher() -> AnyPublisher<Void, Never> {
        isFinishedSubject.eraseToAnyPublisher()
    }

    public func startEditing() {
        isInEditMode = true
    }

    public func saveChanges() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await editor.update(id: storedMetdata.id, item: storedCode, edits: editingModel.detail)
            isInEditMode = false
            editingModel.didPersist()
        } catch {
            let error = OperationError.save
            didEncounterErrorSubject.send(error)
        }
    }

    public func deleteCode() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await editor.deleteCode(id: storedMetdata.id)
            isFinishedSubject.send()
        } catch {
            let error = OperationError.delete
            didEncounterErrorSubject.send(error)
        }
    }

    public func done() {
        if isInEditMode {
            isInEditMode = false
            editingModel.restoreInitialState()
        } else {
            isFinishedSubject.send()
        }
    }
}

// MARK: - Error

public extension OTPCodeDetailViewModel {
    enum OperationError: String, Error, Identifiable, LocalizedError, Equatable {
        case save
        case delete

        public var description: String {
            switch self {
            case .save:
                return localized(key: "codeDetail.action.save.error.description")
            case .delete:
                return localized(key: "codeDetail.action.delete.error.description")
            }
        }

        public var errorDescription: String? {
            description
        }

        public var id: some Hashable {
            rawValue
        }
    }
}

// MARK: - Titles

public extension OTPCodeDetailViewModel {
    var createdDateTitle: String {
        localized(key: "codeDetail.listSection.created.title")
    }

    var createdDateValue: String {
        storedMetdata.created.formatted(date: .abbreviated, time: .omitted)
    }

    var updatedDateTitle: String {
        localized(key: "codeDetail.listSection.updated.title")
    }

    var updatedDateValue: String {
        storedMetdata.updated.formatted(date: .abbreviated, time: .omitted)
    }

    var doneEditingTitle: String {
        localized(key: "feedViewModel.doneEditing.title")
    }

    var saveEditsTitle: String {
        localized(key: "feedViewModel.saveEdits.title")
    }

    var cancelEditsTitle: String {
        localized(key: "feedViewModel.cancelEdits.title")
    }

    var startEditingTitle: String {
        localized(key: "feedViewModel.edit.title")
    }
}

extension OTPCodeDetailViewModel {
    private static func makeInfoEntries(_ code: OTPAuthCode) -> [DetailEntry] {
        let formatter = OTPCodeDetailFormatter(code: code)
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
