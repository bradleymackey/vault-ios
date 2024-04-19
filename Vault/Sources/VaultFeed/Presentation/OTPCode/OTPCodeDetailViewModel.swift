import Combine
import Foundation
import FoundationExtensions
import VaultCore

@MainActor
@Observable
public final class OTPCodeDetailViewModel {
    public var editingModel: DetailEditingModel<OTPCodeDetailEdits>

    public let storedCode: OTPAuthCode
    public let storedMetdata: StoredVaultItem.Metadata
    private let editor: any OTPCodeDetailEditor
    private let detailEditState = DetailEditState<OTPCodeDetailEdits>()
    private let didEncounterErrorSubject = PassthroughSubject<any Error, Never>()
    private let isFinishedSubject = PassthroughSubject<Void, Never>()

    public init(
        storedCode: OTPAuthCode,
        storedMetadata: StoredVaultItem.Metadata,
        editor: any OTPCodeDetailEditor
    ) {
        self.storedCode = storedCode
        storedMetdata = storedMetadata
        self.editor = editor
        editingModel = DetailEditingModel<OTPCodeDetailEdits>(detail: .init(
            issuerTitle: storedCode.data.issuer ?? "",
            accountNameTitle: storedCode.data.accountName,
            description: storedMetadata.userDescription ?? ""
        ))
    }

    public var isSaving: Bool {
        detailEditState.isSaving
    }

    public var isInEditMode: Bool {
        detailEditState.isInEditMode
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

    public func didEncounterErrorPublisher() -> AnyPublisher<any Error, Never> {
        didEncounterErrorSubject.eraseToAnyPublisher()
    }

    /// Publishes when we are done looking at a given code, and should dismiss.
    public func isFinishedPublisher() -> AnyPublisher<Void, Never> {
        isFinishedSubject.eraseToAnyPublisher()
    }

    public func startEditing() {
        detailEditState.startEditing()
    }

    public func saveChanges() async {
        do {
            try await detailEditState.saveChanges {
                try await editor.update(id: storedMetdata.id, item: storedCode, edits: editingModel.detail)
                editingModel.didPersist()
            }
        } catch {
            didEncounterErrorSubject.send(error)
        }
    }

    public func deleteCode() async {
        do {
            try await detailEditState.deleteItem {
                try await editor.deleteCode(id: storedMetdata.id)
            } finished: {
                isFinishedSubject.send()
            }
        } catch {
            didEncounterErrorSubject.send(error)
        }
    }

    public func done() {
        detailEditState.exitCurrentModeClearingDirtyState {
            editingModel.restoreInitialState()
        } finished: {
            isFinishedSubject.send()
        }
    }
}

// MARK: - Titles

extension OTPCodeDetailViewModel {
    public var createdDateTitle: String {
        localized(key: "codeDetail.listSection.created.title")
    }

    public var createdDateValue: String {
        storedMetdata.created.formatted(date: .abbreviated, time: .omitted)
    }

    public var updatedDateTitle: String {
        localized(key: "codeDetail.listSection.updated.title")
    }

    public var updatedDateValue: String {
        storedMetdata.updated.formatted(date: .abbreviated, time: .omitted)
    }

    public var doneEditingTitle: String {
        localized(key: "feedViewModel.doneEditing.title")
    }

    public var saveEditsTitle: String {
        localized(key: "feedViewModel.saveEdits.title")
    }

    public var cancelEditsTitle: String {
        localized(key: "feedViewModel.cancelEdits.title")
    }

    public var startEditingTitle: String {
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
