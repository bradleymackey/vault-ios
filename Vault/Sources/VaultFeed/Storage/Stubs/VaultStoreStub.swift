import Foundation
import FoundationExtensions

/// A vault store where return values can be easily stubbed for testing or
/// other instances where we don't need a fully functional store.
///
/// This should be able to be used in place of any full `VaultStore`.
@MainActor
public final class VaultStoreStub: VaultStore, VaultTagStore {
    public init() {}

    public enum CalledMethod: Equatable, Hashable {
        case retrieve
        case insert
        case update
        case delete
        case export
        case reorder
        case retrieveTags
        case insertTag
        case updateTag
        case deleteTag
    }

    public private(set) var calledMethods: [CalledMethod] = []

    public var retrieveQueryResult = VaultRetrievalResult<VaultItem>()
    public var retrieveQueryCalled: (VaultStoreQuery) throws -> Void = { _ in }
    public func retrieve(query: VaultStoreQuery) async throws -> VaultRetrievalResult<VaultItem> {
        calledMethods.append(.retrieve)
        try retrieveQueryCalled(query)
        return retrieveQueryResult
    }

    public var insertStoreCalled: (VaultItem.Write) -> Void = { _ in }
    public func insert(item: VaultItem.Write) async throws -> Identifier<VaultItem> {
        calledMethods.append(.insert)
        insertStoreCalled(item)
        return .new()
    }

    public var updateStoreCalled: (Identifier<VaultItem>, VaultItem.Write) -> Void = { _, _ in }
    public func update(id: Identifier<VaultItem>, item: VaultItem.Write) async throws {
        calledMethods.append(.update)
        updateStoreCalled(id, item)
    }

    public var deleteStoreCalled: (Identifier<VaultItem>) -> Void = { _ in }
    public func delete(id: Identifier<VaultItem>) async throws {
        calledMethods.append(.delete)
        deleteStoreCalled(id)
    }

    public var exportVaultHandler: (String) -> VaultApplicationPayload = { _ in
        VaultApplicationPayload(userDescription: "any", items: [], tags: [])
    }

    public func exportVault(userDescription: String) async throws -> VaultApplicationPayload {
        calledMethods.append(.export)
        return exportVaultHandler(userDescription)
    }

    public var reorderCalled: (Set<Identifier<VaultItem>>, VaultReorderingPosition) -> Void = { _, _ in }
    public func reorder(
        items: Set<Identifier<VaultItem>>,
        to position: VaultReorderingPosition
    ) async throws {
        calledMethods.append(.reorder)
        reorderCalled(items, position)
    }

    public var retrieveTagsCallCount = 0
    public var retrieveTagsResult: Result<[VaultItemTag], any Error> = .success([])
    public func retrieveTags() async throws -> [VaultItemTag] {
        calledMethods.append(.retrieveTags)
        retrieveTagsCallCount += 1
        return try retrieveTagsResult.get()
    }

    public var insertTagCallCount = 0
    public var insertTagCalled: (VaultItemTag.Write) -> Identifier<VaultItemTag> = { _ in .new() }
    public func insertTag(item: VaultItemTag.Write) async throws -> Identifier<VaultItemTag> {
        calledMethods.append(.insertTag)
        insertTagCallCount += 1
        return insertTagCalled(item)
    }

    public var updateTagCallCount = 0
    public var updateTagCalled: (Identifier<VaultItemTag>, VaultItemTag.Write) -> Void = { _, _ in }
    public func updateTag(id: Identifier<VaultItemTag>, item: VaultItemTag.Write) async throws {
        calledMethods.append(.updateTag)
        updateTagCallCount += 1
        updateTagCalled(id, item)
    }

    public var deleteTagCallCount = 0
    public var deleteTagCalled: (Identifier<VaultItemTag>) -> Void = { _ in }
    public func deleteTag(id: Identifier<VaultItemTag>) async throws {
        calledMethods.append(.deleteTag)
        deleteTagCallCount += 1
        deleteTagCalled(id)
    }
}

// MARK: - Helpers

extension VaultStoreStub {
    public static var empty: VaultStoreStub {
        .init()
    }
}
