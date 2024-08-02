import Foundation
import FoundationExtensions

/// A vault store that always errors on every method call.
@MainActor
public final class VaultStoreErroring: VaultStore, VaultTagStoreReader {
    public var error: any Error
    public init(error: any Error) {
        self.error = error
    }

    public var retrieveQueryCalled: (VaultStoreQuery) -> Void = { _ in }
    public func retrieve(query: VaultStoreQuery) async throws -> VaultRetrievalResult<VaultItem> {
        retrieveQueryCalled(query)
        throw error
    }

    public func insert(item _: VaultItem.Write) async throws -> Identifier<VaultItem> {
        throw error
    }

    public func update(id _: Identifier<VaultItem>, item _: VaultItem.Write) async throws {
        throw error
    }

    public func delete(id _: Identifier<VaultItem>) async throws {
        throw error
    }

    public func exportVault(userDescription _: String) async throws -> VaultApplicationPayload {
        throw error
    }

    public func retrieveTags() async throws -> [VaultItemTag] {
        throw error
    }
}
