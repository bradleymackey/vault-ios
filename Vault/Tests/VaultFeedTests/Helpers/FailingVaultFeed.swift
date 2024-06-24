import Foundation
import VaultFeed

class FailingVaultFeed: VaultFeed {
    struct StubError: Error {}

    func reloadData() async {
        // noop
    }

    func create(item _: VaultItem.Write) async throws {
        throw StubError()
    }

    func update(id _: UUID, item _: VaultItem.Write) async throws {
        throw StubError()
    }

    func delete(id _: UUID) async throws {
        throw StubError()
    }
}
