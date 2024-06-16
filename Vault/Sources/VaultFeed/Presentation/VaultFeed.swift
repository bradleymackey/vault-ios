import Foundation

/// A feed of vault items.
@MainActor
public protocol VaultFeed {
    /// The feed should load all initial data.
    func reloadData() async

    /// Creates a new valut item.
    func create(item: StoredVaultItem.Write) async throws

    /// An update was made to the given vault item.
    ///
    /// The feed should update this data and show the changes.
    func update(id: UUID, item: StoredVaultItem.Write) async throws

    func delete(id: UUID) async throws
}
