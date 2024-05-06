import Combine
import Foundation
import FoundationExtensions
import VaultCore

@MainActor
@Observable
public final class OTPCodeDetailViewModel: DetailViewModel {
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
        let detailEdits = OTPCodeDetailEdits(
            hydratedFromCode: storedCode,
            userDescription: storedMetadata.userDescription ?? ""
        )
        editingModel = DetailEditingModel<OTPCodeDetailEdits>(detail: detailEdits)
    }

    public var isInitialCreation: Bool {
        // TODO: define initial creation state
        false
    }

    public var isSaving: Bool {
        detailEditState.isSaving
    }

    public var isInEditMode: Bool {
        detailEditState.isInEditMode
    }

    public var visibleIssuerTitle: String {
        if editingModel.detail.issuerTitle.isNotEmpty {
            editingModel.detail.issuerTitle
        } else {
            strings.siteNameEmptyTitle
        }
    }

    public var detailMenuItems: [DetailMenuItem] {
        let details = DetailMenuItem(
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
                try await editor.updateCode(id: storedMetdata.id, item: storedCode, edits: editingModel.detail)
                editingModel.didPersist()
            }
        } catch {
            didEncounterErrorSubject.send(error)
        }
    }

    public func delete() async {
        await deleteCode()
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
    public struct Strings: DetailViewModelStrings {
        static let shared = Strings()
        private init() {}

        public let title = localized(key: "codeDetail.title")
        public let deleteConfirmTitle = localized(key: "codeDetail.action.delete.confirm.title")
        public let deleteItemTitle = localized(key: "codeDetail.action.delete.entity.title")
        public let deleteConfirmSubtitle = localized(key: "codeDetail.action.delete.confirm.subtitle")
        public let createdDateTitle = localized(key: "codeDetail.listSection.created.title")
        public let updatedDateTitle = localized(key: "codeDetail.listSection.updated.title")
        public let doneEditingTitle = localized(key: "feedViewModel.doneEditing.title")
        public let saveEditsTitle = localized(key: "feedViewModel.saveEdits.title")
        public let cancelEditsTitle = localized(key: "feedViewModel.cancelEdits.title")
        public let startEditingTitle = localized(key: "feedViewModel.edit.title")
        public let siteNameTitle = localized(key: "codeDetail.field.siteName.title")
        public let siteNameEmptyTitle = localized(key: "codeDetail.field.siteName.empty.title")
        public let accountNameTitle = localized(key: "codeDetail.field.accountName.title")
        public let accountNameExample = localized(key: "codeDetail.field.accountName.example")
        public let descriptionTitle = localized(key: "codeDetail.description.title")
        public let descriptionSubtitle = localized(key: "codeDetail.description.subtitle")
    }

    public var strings: Strings {
        Strings.shared
    }

    public var createdDateValue: String {
        storedMetdata.created.formatted(date: .abbreviated, time: .shortened)
    }

    public var updatedDateValue: String {
        storedMetdata.updated.formatted(date: .abbreviated, time: .shortened)
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
