import Foundation
import VaultCore

/// Can read all stored vault tags.
///
/// @mockable
public protocol VaultTagStoreReader: Sendable {
    /// Fetches all tags from storage.
    func retrieve() async throws -> [VaultItemTag]
}

/// Can write all stored vault tags.
///
/// @mockable
public protocol VaultTagStoreWriter: Sendable {
    /// Creates a new tag with the given user visible data.
    @discardableResult
    func insert(item: VaultItemTag.Write) async throws -> VaultItemTag.Identifier

    /// Updates user-visible data for a given tag.
    func update(id: VaultItemTag.Identifier, item: VaultItemTag.Write) async throws

    /// - Throws: if tag is in use, or there was an error in the backing layer.
    /// Has no effect if the tag does not exist.
    func delete(id: VaultItemTag.Identifier) async throws
}
