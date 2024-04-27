import Foundation
import VaultCore
import VaultFeed

class MockSecureNoteDetailEditor: SecureNoteDetailEditor {
    enum Operation: Equatable, Hashable {
        case create
        case update
        case delete
    }

    private(set) var operationsPerformed = [Operation]()

    var createNoteResult: Result<Void, any Error> = .success(())
    func create(initialEdits _: SecureNoteDetailEdits) async throws {
        operationsPerformed.append(.create)
        try createNoteResult.get()
    }

    var updateNoteResult: Result<Void, any Error> = .success(())
    func update(id _: UUID, item _: SecureNote, edits _: SecureNoteDetailEdits) async throws {
        operationsPerformed.append(.update)
        try updateNoteResult.get()
    }

    var deleteNoteResult: Result<Void, any Error> = .success(())
    func deleteNote(id _: UUID) async throws {
        operationsPerformed.append(.delete)
        try deleteNoteResult.get()
    }
}
