import Foundation
import VaultFeed
import VaultiOS

@MainActor
final class MockOTPCodeStore: VaultStore {
    init() {}
    var codesToRetrieve = [StoredVaultItem]()
    var didRetrieveData: () -> Void = {}
    func retrieve() async throws -> [StoredVaultItem] {
        didRetrieveData()
        return codesToRetrieve
    }

    var codesToRetrieveMatchingQuery = [StoredVaultItem]()
    var didRetrieveDataMatchingQuery: (String) -> Void = { _ in }
    func retrieve(matching query: String) async throws -> [StoredVaultItem] {
        didRetrieveDataMatchingQuery(query)
        return codesToRetrieveMatchingQuery
    }

    func delete(id _: UUID) async throws {
        // noop
    }

    func insert(item _: StoredVaultItem.Write) async throws -> UUID {
        UUID()
    }

    func update(id _: UUID, item _: StoredVaultItem.Write) async throws {
        // noop
    }
}
