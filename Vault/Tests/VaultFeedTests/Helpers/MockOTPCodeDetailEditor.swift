import Foundation
import VaultCore
import VaultFeed

class MockOTPCodeDetailEditor: OTPCodeDetailEditor {
    enum Operation: Equatable, Hashable {
        case create
        case update
        case delete
    }

    private(set) var operationsPerformed = [Operation]()

    var createCodeResult: Result<Void, any Error> = .success(())
    var createCodeCalled: (OTPCodeDetailEdits) async -> Void = { _ in }
    func createCode(initialEdits: OTPCodeDetailEdits) async throws {
        operationsPerformed.append(.create)
        await createCodeCalled(initialEdits)
        try createCodeResult.get()
    }

    var updateCodeResult: Result<Void, any Error> = .success(())
    var updateCodeCalled: (UUID, OTPAuthCode, OTPCodeDetailEdits) async -> Void = { _, _, _ in }
    func updateCode(id: UUID, item: OTPAuthCode, edits: OTPCodeDetailEdits) async throws {
        operationsPerformed.append(.update)
        await updateCodeCalled(id, item, edits)
        try updateCodeResult.get()
    }

    var deleteCodeResult: Result<Void, any Error> = .success(())
    var deleteCodeCalled: (UUID) async -> Void = { _ in }
    func deleteCode(id: UUID) async throws {
        operationsPerformed.append(.delete)
        await deleteCodeCalled(id)
        try deleteCodeResult.get()
    }
}
