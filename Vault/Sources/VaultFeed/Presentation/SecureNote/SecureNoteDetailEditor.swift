import Foundation
import FoundationExtensions
import VaultCore

/// @mockable
@MainActor
public protocol SecureNoteDetailEditor {
    func createNote(initialEdits: SecureNoteDetailEdits) async throws
    func updateNote(id: Identifier<VaultItem>, item: SecureNote, edits: SecureNoteDetailEdits) async throws
    func deleteNote(id: Identifier<VaultItem>) async throws
}
