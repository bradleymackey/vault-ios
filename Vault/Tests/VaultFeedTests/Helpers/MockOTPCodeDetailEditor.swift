import Foundation
import VaultCore
import VaultFeed

class MockOTPCodeDetailEditor: OTPCodeDetailEditor {
    enum Operation: Equatable, Hashable {
        case update
        case delete
    }

    private(set) var operationsPerformed = [Operation]()

    var updateCodeResult: Result<Void, any Error> = .success(())
    var updateCodeCalled: (UUID, OTPAuthCode, OTPCodeDetailEdits) async -> Void = { _, _, _ in }
    func update(id: UUID, item: OTPAuthCode, edits: OTPCodeDetailEdits) async throws {
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
