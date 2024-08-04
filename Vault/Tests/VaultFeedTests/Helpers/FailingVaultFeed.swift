import Foundation
import FoundationExtensions
import VaultFeed

class FailingVaultFeed: VaultFeed {
    struct StubError: Error {}

    func reloadData() async {
        // noop
    }

    func create(item _: VaultItem.Write) async throws {
        throw StubError()
    }

    func update(id _: Identifier<VaultItem>, item _: VaultItem.Write) async throws {
        throw StubError()
    }

    func delete(id _: Identifier<VaultItem>) async throws {
        throw StubError()
    }

    func reorder(items _: Set<Identifier<VaultItem>>, to _: VaultReorderingPosition) async throws {
        throw StubError()
    }
}
