import Combine
import Foundation
import VaultCore

@MainActor
public final class SecureNoteDetailViewModel {
    public var editingModel: DetailEditingModel<SecureNoteDetailEdits>

    private let storedNote: SecureNote
    private let storedMetadata: StoredVaultItem.Metadata
    private let detailEditState = DetailEditState<SecureNoteDetailEdits>()
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

    public func startEditing() {
        detailEditState.startEditing()
    }
}
