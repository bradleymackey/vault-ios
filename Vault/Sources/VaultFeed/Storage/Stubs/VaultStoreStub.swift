import Foundation

/// A vault store where return values can be easily stubbed for testing or
/// other instances where we don't need a fully functional store.
///
/// This should be able to be used in place of any full `VaultStore`.
@MainActor
public final class VaultStoreStub: VaultStore {
    public init() {}

    public var codes = VaultRetrievalResult<VaultItem>()
    public var retrieveStoreCalled: () -> Void = {}
    public func retrieve() async throws -> VaultRetrievalResult<VaultItem> {
        retrieveStoreCalled()
        return codes
    }

    public var codesMatchingQuery = VaultRetrievalResult<VaultItem>()
    public var retrieveStoreMatchingQueryCalled: (String) -> Void = { _ in }
    public func retrieve(matching query: String) async throws -> VaultRetrievalResult<VaultItem> {
        retrieveStoreMatchingQueryCalled(query)
        return codesMatchingQuery
    }

    public var retrieveResult = VaultRetrievalResult<VaultItem>()
    public var retrieveQueryCalled: (VaultStoreQuery) -> Void = { _ in }
    public func retrieve(query: VaultStoreQuery) async throws -> VaultRetrievalResult<VaultItem> {
        retrieveQueryCalled(query)
        return retrieveResult
    }

    public var insertStoreCalled: () -> Void = {}
    public func insert(item _: VaultItem.Write) async throws -> UUID {
        insertStoreCalled()
        return UUID()
    }

    public var updateStoreCalled: () -> Void = {}
    public func update(id _: UUID, item _: VaultItem.Write) async throws {
        updateStoreCalled()
    }

    public var deleteStoreCalled: () -> Void = {}
    public func delete(id _: UUID) async throws {
        deleteStoreCalled()
    }

    public var exportVaultHandler: (String) -> VaultApplicationPayload = { _ in
        VaultApplicationPayload(userDescription: "any", items: [], tags: [])
    }

    public func exportVault(userDescription: String) async throws -> VaultApplicationPayload {
        exportVaultHandler(userDescription)
    }
}

// MARK: - Helpers

extension VaultStoreStub {
    public static var empty: VaultStoreStub {
        .init()
    }
}
