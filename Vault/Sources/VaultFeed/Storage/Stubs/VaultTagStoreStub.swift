import Foundation
import VaultCore

@MainActor
public final class VaultTagStoreStub: VaultTagStore {
    public init() {}

    public var retrieveTagsCallCount = 0
    public var retrieveTagsCalled: () -> Void = {}
    public var retrieveTagsResult = [VaultItemTag]()
    public func retrieveTags() async throws -> [VaultItemTag] {
        retrieveTagsCallCount += 1
        retrieveTagsCalled()
        return retrieveTagsResult
    }

    public var insertTagCallCount = 0
    public var insertTagResult = VaultItemTag.Identifier(id: UUID())
    public var insertTagCalled: (VaultItemTag.Write) -> Void = { _ in }
    public func insertTag(item: VaultItemTag.Write) async throws -> VaultItemTag.Identifier {
        insertTagCallCount += 1
        insertTagCalled(item)
        return insertTagResult
    }

    public var updateTagCallCount = 0
    public var updateTagCalled: (VaultItemTag.Identifier, VaultItemTag.Write) -> Void = { _, _ in }
    public func updateTag(id: VaultItemTag.Identifier, item: VaultItemTag.Write) async throws {
        updateTagCallCount += 1
        updateTagCalled(id, item)
    }

    public var deleteTagCallCount = 0
    public var deleteTagCalled: (VaultItemTag.Identifier) -> Void = { _ in }
    public func deleteTag(id: VaultItemTag.Identifier) async throws {
        deleteTagCallCount += 1
        deleteTagCalled(id)
    }
}

// MARK: - Helpers

extension VaultTagStoreStub {
    public static var empty: VaultTagStoreStub {
        .init()
    }
}
