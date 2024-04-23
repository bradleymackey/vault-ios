import Combine
import Foundation
import VaultCore

@MainActor
@Observable
public final class SecureNoteDetailViewModel: DetailViewModel {
    public var editingModel: DetailEditingModel<SecureNoteDetailEdits>

    private let storedNote: SecureNote
    private let storedMetadata: StoredVaultItem.Metadata
    private let detailEditState = DetailEditState<SecureNoteDetailEdits>()
    private let didEncounterErrorSubject = PassthroughSubject<any Error, Never>()
    private let isFinishedSubject = PassthroughSubject<Void, Never>()
    private let editor: any SecureNoteDetailEditor

    public init(storedNote: SecureNote, storedMetadata: StoredVaultItem.Metadata, editor: any SecureNoteDetailEditor) {
        self.storedNote = storedNote
        self.storedMetadata = storedMetadata
        self.editor = editor
        editingModel = .init(detail: .init(
            description: storedMetadata.userDescription ?? "",
            title: storedNote.title,
            contents: storedNote.contents
        ))
    }

    public var isInEditMode: Bool {
        detailEditState.isInEditMode
    }

    public var isSaving: Bool {
        detailEditState.isSaving
    }

    public func startEditing() {
        detailEditState.startEditing()
    }

    public func didEncounterErrorPublisher() -> AnyPublisher<any Error, Never> {
        didEncounterErrorSubject.eraseToAnyPublisher()
    }

    /// When we are done looking at the detail page and should submit.
    public func isFinishedPublisher() -> AnyPublisher<Void, Never> {
        isFinishedSubject.eraseToAnyPublisher()
    }

    public func saveChanges() async {
        do {
            try await detailEditState.saveChanges {
                try await editor.update(id: storedMetadata.id, item: storedNote, edits: editingModel.detail)
                editingModel.didPersist()
            }
        } catch {
            didEncounterErrorSubject.send(error)
        }
    }

    public func delete() async {
        await deleteNote()
    }

    public func deleteNote() async {
        do {
            try await detailEditState.deleteItem {
                try await editor.deleteNote(id: storedMetadata.id)
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

extension SecureNoteDetailViewModel {
    public struct Strings: DetailViewModelStrings {
        static let shared = Strings()
        private init() {}

        public let title = localized(key: "noteDetail.title")
        public let deleteItemTitle = localized(key: "noteDetail.action.delete.entity.title")
        public let deleteConfirmTitle = localized(key: "noteDetail.action.delete.confirm.title")
        public let deleteConfirmSubtitle = localized(key: "noteDetail.action.delete.confirm.subtitle")
        public let descriptionTitle = localized(key: "noteDetail.description.title")
        public let descriptionSubtitle = localized(key: "noteDetail.description.subtitle")
        public let createdDateTitle = localized(key: "noteDetail.listSection.created.title")
        public let updatedDateTitle = localized(key: "noteDetail.listSection.updated.title")
        public let doneEditingTitle = localized(key: "feedViewModel.doneEditing.title")
        public let saveEditsTitle = localized(key: "feedViewModel.saveEdits.title")
        public let cancelEditsTitle = localized(key: "feedViewModel.cancelEdits.title")
        public let startEditingTitle = localized(key: "feedViewModel.edit.title")
        public let noteTitle = localized(key: "noteDetail.field.noteTitle.title")
        public let noteTitleExample = localized(key: "noteDetail.field.noteTitle.example")
        public let noteDescription = localized(key: "noteDetail.field.noteDescription.title")
        public let noteContentsTitle = localized(key: "noteDetail.field.noteContents.title")
    }

    public var strings: Strings {
        Strings.shared
    }

    public var createdDateValue: String {
        storedMetadata.created.formatted(date: .abbreviated, time: .shortened)
    }

    public var updatedDateValue: String {
        storedMetadata.updated.formatted(date: .abbreviated, time: .shortened)
    }
}
