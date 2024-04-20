import Combine
import Foundation
import VaultCore

@MainActor
@Observable
public final class SecureNoteDetailViewModel {
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
    public var createdDateTitle: String {
        localized(key: "noteDetail.listSection.created.title")
    }

    public var createdDateValue: String {
        storedMetadata.created.formatted(date: .abbreviated, time: .omitted)
    }

    public var updatedDateTitle: String {
        localized(key: "noteDetail.listSection.updated.title")
    }

    public var updatedDateValue: String {
        storedMetadata.updated.formatted(date: .abbreviated, time: .omitted)
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
