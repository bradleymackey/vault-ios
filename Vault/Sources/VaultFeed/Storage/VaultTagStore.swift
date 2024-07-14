import Foundation
import VaultCore

public typealias VaultTagStore = VaultTagStoreReader & VaultTagStoreWriter

/// Can read all stored vault tags.
///
/// @mockable
public protocol VaultTagStoreReader: Sendable {
    /// Fetches all tags from storage.
    func retrieveTags() async throws -> [VaultItemTag]
}

/// Can write all stored vault tags.
///
/// @mockable
public protocol VaultTagStoreWriter: Sendable {
    /// Creates a new tag with the given user visible data.
    @discardableResult
    func insertTag(item: VaultItemTag.Write) async throws -> VaultItemTag.Identifier

    /// Updates user-visible data for a given tag.
    func updateTag(id: VaultItemTag.Identifier, item: VaultItemTag.Write) async throws

    /// - Throws: if tag is in use, or there was an error in the backing layer.
    /// Has no effect if the tag does not exist.
    func deleteTag(id: VaultItemTag.Identifier) async throws
}
