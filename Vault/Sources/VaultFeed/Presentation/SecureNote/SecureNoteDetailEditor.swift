import Foundation
import VaultCore

public protocol SecureNoteDetailEditor {
    func update(id: UUID, item: SecureNote, edits: SecureNoteDetailEdits) async throws
    func deleteNote(id: UUID) async throws
}
