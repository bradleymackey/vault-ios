import Foundation
import FoundationExtensions
import VaultCore

public typealias VaultStore = VaultStoreExporter & VaultStoreReader & VaultStoreReorderable & VaultStoreWriter

public protocol VaultStoreReader: Sendable {
    /// Retrieve items matching the given query.
    func retrieve(query: VaultStoreQuery) async throws -> VaultRetrievalResult<VaultItem>
}

public protocol VaultStoreWriter: Sendable {
    /// Create a new item in the vault store, based off the provided data.
    ///
    /// The id will be created by the underlying storage layer and returned.
    ///
    /// - Returns: The unique ID of the newly created item.
    @discardableResult
    func insert(item: VaultItem.Write) async throws -> Identifier<VaultItem>

    /// Update the item with the given `id`.
    func update(id: Identifier<VaultItem>, item: VaultItem.Write) async throws

    /// Delete the item with the specific `id`.
    ///
    /// This should have no effect if the item does not exist.
    func delete(id: Identifier<VaultItem>) async throws
}

/// @mockable
public protocol VaultStoreReorderable: Sendable {
    /// Reorder the item with the given `id` to the given position and current view.
    func reorder(items: Set<Identifier<VaultItem>>, to position: VaultReorderingPosition) async throws
}

/// @mockable
public protocol VaultStoreExporter: Sendable {
    func exportVault(userDescription: String) async throws -> VaultApplicationPayload
}
