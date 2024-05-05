import Foundation
import VaultCore

public protocol SecureNoteDetailEditor {
    func createNote(initialEdits: SecureNoteDetailEdits) async throws
    func updateNote(id: UUID, item: SecureNote, edits: SecureNoteDetailEdits) async throws
    func deleteNote(id: UUID) async throws
}
