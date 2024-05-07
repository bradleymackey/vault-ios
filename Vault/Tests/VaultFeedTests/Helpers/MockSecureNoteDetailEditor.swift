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

    var createNoteCalled: () -> Void = {}
    var createNoteResult: Result<Void, any Error> = .success(())
    func createNote(initialEdits _: SecureNoteDetailEdits) async throws {
        createNoteCalled()
        operationsPerformed.append(.create)
        try createNoteResult.get()
    }

    var updateNoteCalled: () -> Void = {}
    var updateNoteResult: Result<Void, any Error> = .success(())
    func updateNote(id _: UUID, item _: SecureNote, edits _: SecureNoteDetailEdits) async throws {
        updateNoteCalled()
        operationsPerformed.append(.update)
        try updateNoteResult.get()
    }

    var deleteNoteResult: Result<Void, any Error> = .success(())
    func deleteNote(id _: UUID) async throws {
        operationsPerformed.append(.delete)
        try deleteNoteResult.get()
    }
}
