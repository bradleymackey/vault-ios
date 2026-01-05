import Foundation
import FoundationExtensions
import VaultCore

public typealias VaultStore = VaultStoreExporter & VaultStoreHOTPIncrementer & VaultStoreReader &
    VaultStoreReorderable &
    VaultStoreWriter

public protocol VaultStoreReader: Sendable {
    /// Retrieve items matching the given query.
    func retrieve(query: VaultStoreQuery) async throws -> VaultRetrievalResult<VaultItem>

    /// Returns a boolean if there is any data in the store at all.
    ///
    /// This checks all items, including hidden and locked ones.
    var hasAnyItems: Bool { get async throws }
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
public protocol VaultStoreHOTPIncrementer: Sendable {
    func incrementCounter(id: Identifier<VaultItem>) async throws
}

/// @mockable
public protocol VaultStoreReorderable: Sendable {
    /// Reorder the item with the given `id` to the given position and current view.
    func reorder(
        items: Set<Identifier<VaultItem>>,
        to position: VaultReorderingPosition,
    ) async throws
}

/// @mockable
public protocol VaultStoreExporter: Sendable {
    func exportVault(userDescription: String) async throws -> VaultApplicationPayload
}

/// @mockable
public protocol VaultStoreImporter: Sendable {
    /// Imports the data in the payload without affecting existing data.
    ///
    ///  - note: If there are duplicate items, the most recently edited one will be retained.
    func importAndMergeVault(payload: VaultApplicationPayload) async throws

    /// Imports the data in the payload, deleting existing vault data.
    func importAndOverrideVault(payload: VaultApplicationPayload) async throws
}

/// @mockable
public protocol VaultStoreDeleter: Sendable {
    /// Deletes the entire vault immediately.
    ///
    /// - note: This operation is atomic and will either complete fully or not at all.
    func deleteVault() async throws
}

/// @mockable
public protocol VaultStoreKillphraseDeleter: Sendable {
    /// Deletes items matching the given killphrase.
    /// - Returns: `true` if any items were deleted, `false` otherwise
    @discardableResult
    func deleteItems(matchingKillphrase: String) async -> Bool
}
