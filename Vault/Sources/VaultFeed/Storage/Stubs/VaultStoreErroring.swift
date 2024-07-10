import Foundation

/// A vault store that always errors on every method call.
@MainActor
public final class VaultStoreErroring: VaultStore {
    public var error: any Error
    public init(error: any Error) {
        self.error = error
    }

    public var retrieveStoreCalled: () -> Void = {}
    public func retrieve() async throws -> VaultRetrievalResult<VaultItem> {
        retrieveStoreCalled()
        throw error
    }

    public var retrieveStoreMatchingQueryCalled: (String) -> Void = { _ in }
    public func retrieve(matching query: String) async throws -> VaultRetrievalResult<VaultItem> {
        retrieveStoreMatchingQueryCalled(query)
        throw error
    }

    public var retrieveQueryCalled: (VaultStoreQuery) -> Void = { _ in }
    public func retrieve(query: VaultStoreQuery) async throws -> VaultRetrievalResult<VaultItem> {
        retrieveQueryCalled(query)
        throw error
    }

    public func insert(item _: VaultItem.Write) async throws -> UUID {
        throw error
    }

    public func update(id _: UUID, item _: VaultItem.Write) async throws {
        throw error
    }

    public func delete(id _: UUID) async throws {
        throw error
    }

    public func exportVault(userDescription _: String) async throws -> VaultApplicationPayload {
        throw error
    }
}
