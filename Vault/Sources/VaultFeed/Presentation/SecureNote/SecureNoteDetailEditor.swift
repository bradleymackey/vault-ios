import Foundation
import VaultCore

public protocol SecureNoteDetailEditor {
    func create(initialEdits: SecureNoteDetailEdits) async throws
    func update(id: UUID, item: SecureNote, edits: SecureNoteDetailEdits) async throws
    func deleteNote(id: UUID) async throws
}
