import Foundation

/// A vault store where return values can be easily stubbed for testing or
/// other instances where we don't need a fully functional store.
///
/// This should be able to be used in place of any full `VaultStore`.
@MainActor
public final class VaultStoreStub: VaultStore, VaultTagStoreReader {
    public init() {}

    public var retrieveQueryResult = VaultRetrievalResult<VaultItem>()
    public var retrieveQueryCalled: (VaultStoreQuery) -> Void = { _ in }
    public func retrieve(query: VaultStoreQuery) async throws -> VaultRetrievalResult<VaultItem> {
        retrieveQueryCalled(query)
        return retrieveQueryResult
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

    public var retrieveTagsResult: Result<[VaultItemTag], any Error> = .success([])
    public func retrieveTags() async throws -> [VaultItemTag] {
        try retrieveTagsResult.get()
    }
}

// MARK: - Helpers

extension VaultStoreStub {
    public static var empty: VaultStoreStub {
        .init()
    }
}
