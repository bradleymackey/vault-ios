import Foundation
import VaultCore

public typealias VaultStore = VaultStoreReader & VaultStoreWriter

public protocol VaultStoreReader {
    /// Retrieve all stored codes from storage.
    func retrieve() async throws -> [StoredVaultItem]

    /// Retrieve only vault items that match the given query.
    func retrieve(matching query: String) async throws -> [StoredVaultItem]
}

public protocol VaultStoreWriter {
    /// Insert an `OTPAuthCode` with a unique `id`.
    ///
    /// - Returns: The underlying ID of the entry in the store.
    @discardableResult
    func insert(item: StoredVaultItem.Write) async throws -> UUID

    /// Update the code at the given ID.
    func update(id: UUID, item: StoredVaultItem.Write) async throws

    /// Delete the code with the specific `id`.
    /// Has no effect if the code does not exist.
    func delete(id: UUID) async throws
}
