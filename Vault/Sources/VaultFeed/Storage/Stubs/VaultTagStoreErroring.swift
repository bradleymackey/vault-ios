import Foundation
import VaultCore

@MainActor
public final class VaultTagStoreErroring: VaultTagStore {
    public var error: any Error
    public init(error: any Error) {
        self.error = error
    }

    public func retrieveTags() async throws -> [VaultItemTag] {
        throw error
    }

    public func insertTag(item _: VaultItemTag.Write) async throws -> VaultItemTag.Identifier {
        throw error
    }

    public func updateTag(id _: VaultItemTag.Identifier, item _: VaultItemTag.Write) async throws {
        throw error
    }

    public func deleteTag(id _: VaultItemTag.Identifier) async throws {
        throw error
    }
}
