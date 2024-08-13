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

    public private(set) var retrieveTagsCallCount = 0
    public var retrieveTagsHandler: () throws -> [VaultItemTag] = { [] }
    public func retrieveTags() async throws -> [VaultItemTag] {
        calledMethods.append(.retrieveTags)
        retrieveTagsCallCount += 1
        return try retrieveTagsHandler()
    }

    public private(set) var insertTagCallCount = 0
    public var insertTagHandler: (VaultItemTag.Write) throws -> Identifier<VaultItemTag> = { _ in .new() }
    public func insertTag(item: VaultItemTag.Write) async throws -> Identifier<VaultItemTag> {
        calledMethods.append(.insertTag)
        insertTagCallCount += 1
        return try insertTagHandler(item)
    }

    public private(set) var updateTagCallCount = 0
    public var updateTagHandler: (Identifier<VaultItemTag>, VaultItemTag.Write) throws -> Void = { _, _ in }
    public func updateTag(id: Identifier<VaultItemTag>, item: VaultItemTag.Write) async throws {
        calledMethods.append(.updateTag)
        updateTagCallCount += 1
        try updateTagHandler(id, item)
    }

    public private(set) var deleteTagCallCount = 0
    public var deleteTagHandler: (Identifier<VaultItemTag>) throws -> Void = { _ in }
    public func deleteTag(id: Identifier<VaultItemTag>) async throws {
        calledMethods.append(.deleteTag)
        deleteTagCallCount += 1
        try deleteTagHandler(id)
    }
}

// MARK: - Helpers

extension VaultTagStoreStub {
    public static var empty: VaultTagStoreStub {
        .init()
    }
}
