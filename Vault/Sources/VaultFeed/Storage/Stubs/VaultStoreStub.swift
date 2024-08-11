import Foundation
import FoundationExtensions

/// A vault store where return values can be easily stubbed for testing or
/// other instances where we don't need a fully functional store.
///
/// This should be able to be used in place of any full `VaultStore`.
@MainActor
public final class VaultStoreStub: VaultStore, VaultTagStore {
    public init() {}

    public var retrieveQueryResult = VaultRetrievalResult<VaultItem>()
    public var retrieveQueryCalled: (VaultStoreQuery) -> Void = { _ in }
    public func retrieve(query: VaultStoreQuery) async throws -> VaultRetrievalResult<VaultItem> {
        retrieveQueryCalled(query)
        return retrieveQueryResult
    }

    public var insertStoreCalled: () -> Void = {}
    public func insert(item _: VaultItem.Write) async throws -> Identifier<VaultItem> {
        insertStoreCalled()
        return .new()
    }

    public var updateStoreCalled: () -> Void = {}
    public func update(id _: Identifier<VaultItem>, item _: VaultItem.Write) async throws {
        updateStoreCalled()
    }

    public var deleteStoreCalled: () -> Void = {}
    public func delete(id _: Identifier<VaultItem>) async throws {
        deleteStoreCalled()
    }

    public var exportVaultHandler: (String) -> VaultApplicationPayload = { _ in
        VaultApplicationPayload(userDescription: "any", items: [], tags: [])
    }

    public func exportVault(userDescription: String) async throws -> VaultApplicationPayload {
        exportVaultHandler(userDescription)
    }

    public var reorderCalled: (Set<Identifier<VaultItem>>, VaultReorderingPosition) -> Void = { _, _ in }
    public func reorder(
        items: Set<Identifier<VaultItem>>,
        to position: VaultReorderingPosition
    ) async throws {
        reorderCalled(items, position)
    }

    public var retrieveTagsResult: Result<[VaultItemTag], any Error> = .success([])
    public func retrieveTags() async throws -> [VaultItemTag] {
        try retrieveTagsResult.get()
    }

    public var insertTagCalled: (VaultItemTag.Write) -> Identifier<VaultItemTag> = { _ in .new() }
    public func insertTag(item: VaultItemTag.Write) async throws -> Identifier<VaultItemTag> {
        insertTagCalled(item)
    }

    public var updateTagCalled: (Identifier<VaultItemTag>, VaultItemTag.Write) -> Void = { _, _ in }
    public func updateTag(id: Identifier<VaultItemTag>, item: VaultItemTag.Write) async throws {
        updateTagCalled(id, item)
    }

    public var deleteTagCalled: (Identifier<VaultItemTag>) -> Void = { _ in }
    public func deleteTag(id: Identifier<VaultItemTag>) async throws {
        deleteTagCalled(id)
    }
}

// MARK: - Helpers

extension VaultStoreStub {
    public static var empty: VaultStoreStub {
        .init()
    }
}
