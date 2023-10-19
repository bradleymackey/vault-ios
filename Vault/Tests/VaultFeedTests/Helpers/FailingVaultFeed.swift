import Foundation
import VaultFeed

class FailingVaultFeed: VaultFeed {
    struct StubError: Error {}

    func reloadData() async {
        // noop
    }

    func update(id _: UUID, item _: StoredVaultItem.Write) async throws {
        throw StubError()
    }

    func delete(id _: UUID) async throws {
        throw StubError()
    }
}
