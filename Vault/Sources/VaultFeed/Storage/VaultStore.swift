import Foundation
import VaultCore

public typealias VaultStore = VaultStoreReader & VaultStoreWriter

public protocol VaultStoreReader: Sendable {
    /// Retrieve all stored items.
    func retrieve() async throws -> VaultRetrievalResult

    /// Retrieve only items that match the given query.
    func retrieve(matching query: String) async throws -> VaultRetrievalResult
}

public protocol VaultStoreWriter: Sendable {
    /// Create a new item in the vault store, based off the provided data.
    ///
    /// The id will be created by the underlying storage layer and returned.
    ///
    /// - Returns: The unique ID of the newly created item.
    @discardableResult
    func insert(item: VaultItem.Write) async throws -> UUID

    /// Update the item with the given `id`.
    func update(id: UUID, item: VaultItem.Write) async throws

    /// Delete the item with the specific `id`.
    ///
    /// This should have no effect if the item does not exist.
    func delete(id: UUID) async throws
}
