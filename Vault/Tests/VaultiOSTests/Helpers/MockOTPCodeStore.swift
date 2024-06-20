import Foundation
import VaultFeed
import VaultiOS

@MainActor
final class MockOTPCodeStore: VaultStore {
    init() {}
    var codesToRetrieve = VaultRetrievalResult()
    var didRetrieveData: () -> Void = {}
    func retrieve() async throws -> VaultRetrievalResult {
        didRetrieveData()
        return codesToRetrieve
    }

    var codesToRetrieveMatchingQuery = VaultRetrievalResult()
    var didRetrieveDataMatchingQuery: (String) -> Void = { _ in }
    func retrieve(matching query: String) async throws -> VaultRetrievalResult {
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
