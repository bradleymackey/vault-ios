import Foundation
import FoundationExtensions
import VaultCore

@MainActor
public final class VaultTagStoreStub: VaultTagStore {
    public init() {}

    public enum CalledMethod: Equatable, Hashable {
        case retrieveTags
        case insertTag
        case updateTag
        case deleteTag
    }

    public private(set) var calledMethods: [CalledMethod] = []

    public var retrieveTagsCallCount = 0
    public var retrieveTagsCalled: () -> Void = {}
    public var retrieveTagsResult = [VaultItemTag]()
    public func retrieveTags() async throws -> [VaultItemTag] {
        calledMethods.append(.retrieveTags)
        retrieveTagsCallCount += 1
        retrieveTagsCalled()
        return retrieveTagsResult
    }

    public var insertTagCallCount = 0
    public var insertTagResult = Identifier<VaultItemTag>(id: UUID())
    public var insertTagCalled: (VaultItemTag.Write) -> Void = { _ in }
    public func insertTag(item: VaultItemTag.Write) async throws -> Identifier<VaultItemTag> {
        calledMethods.append(.insertTag)
        insertTagCallCount += 1
        insertTagCalled(item)
        return insertTagResult
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

extension VaultTagStoreStub {
    public static var empty: VaultTagStoreStub {
        .init()
    }
}
