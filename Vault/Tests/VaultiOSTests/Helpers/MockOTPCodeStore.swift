import Foundation
import VaultFeed
import VaultiOS

@MainActor
final class MockOTPCodeStore: VaultStore {
    init() {}
    var codesToRetrieve = VaultRetrievalResult<VaultItem>()
    var didRetrieveData: () -> Void = {}
    func retrieve() async throws -> VaultRetrievalResult<VaultItem> {
        didRetrieveData()
        return codesToRetrieve
    }

    var codesToRetrieveMatchingQuery = VaultRetrievalResult<VaultItem>()
    var didRetrieveDataMatchingQuery: (String) -> Void = { _ in }
    func retrieve(matching query: String) async throws -> VaultRetrievalResult<VaultItem> {
        didRetrieveDataMatchingQuery(query)
        return codesToRetrieveMatchingQuery
    }

    func delete(id _: UUID) async throws {
        // noop
    }

    func insert(item _: VaultItem.Write) async throws -> UUID {
        UUID()
    }

    func update(id _: UUID, item _: VaultItem.Write) async throws {
        // noop
    }
}
