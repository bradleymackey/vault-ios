import Foundation
import VaultFeed

class MockVaultFeed: VaultFeed {
    var calls = [String]()

    func reloadData() async {
        calls.append("\(#function)")
    }

    var createCalled: (VaultItem.Write) -> Void = { _ in }
    func create(item: VaultItem.Write) async throws {
        calls.append(#function)
        createCalled(item)
    }

    var updateCalled: (UUID, VaultItem.Write) -> Void = { _, _ in }
    func update(id: UUID, item: VaultItem.Write) async throws {
        calls.append("\(#function)")
        updateCalled(id, item)
    }

    var deleteCalled: (UUID) -> Void = { _ in }
    func delete(id: UUID) async throws {
        calls.append(#function)
        deleteCalled(id)
    }
}
