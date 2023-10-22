import Combine
import Foundation
import VaultCore

@MainActor
public final class SecureNoteDetailViewModel {
    private let storedNote: SecureNote
    private let storedMetadata: StoredVaultItem.Metadata
    private let editor: any SecureNoteDetailEditor

    public init(storedNote: SecureNote, storedMetadata: StoredVaultItem.Metadata, editor: any SecureNoteDetailEditor) {
        self.storedNote = storedNote
        self.storedMetadata = storedMetadata
        self.editor = editor
    }
}
