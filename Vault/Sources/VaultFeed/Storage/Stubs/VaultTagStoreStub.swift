import Foundation
import VaultCore

@MainActor
public final class VaultTagStoreStub: VaultTagStore {
    public init() {}

    public var retrieveTagsCalled: () -> Void = {}
    public var retrieveTagsResult = [VaultItemTag]()
    public func retrieveTags() async throws -> [VaultItemTag] {
        retrieveTagsCalled()
        return retrieveTagsResult
    }

    public var insertTagResult = VaultItemTag.Identifier(id: UUID())
    public var insertTagCalled: (VaultItemTag.Write) -> Void = { _ in }
    public func insertTag(item: VaultItemTag.Write) async throws -> VaultItemTag.Identifier {
        insertTagCalled(item)
        return insertTagResult
    }

    public var updateTagCalled: (VaultItemTag.Identifier, VaultItemTag.Write) -> Void = { _, _ in }
    public func updateTag(id: VaultItemTag.Identifier, item: VaultItemTag.Write) async throws {
        updateTagCalled(id, item)
    }

    public var deleteTagCalled: (VaultItemTag.Identifier) -> Void = { _ in }
    public func deleteTag(id: VaultItemTag.Identifier) async throws {
        deleteTagCalled(id)
    }
}

// MARK: - Helpers

extension VaultTagStoreStub {
    public static var empty: VaultTagStoreStub {
        .init()
    }
}
