import Foundation
import VaultCore
import VaultFeed

class MockSecureNoteDetailEditor: SecureNoteDetailEditor {
    enum Operation: Equatable, Hashable {
        case update
        case delete
    }

    private(set) var operationsPerformed = [Operation]()

    func update(id _: UUID, item _: SecureNote, edits _: SecureNoteDetailEdits) async throws {
        operationsPerformed.append(.update)
    }

    func deleteNote(id _: UUID) async throws {
        operationsPerformed.append(.delete)
    }
}
