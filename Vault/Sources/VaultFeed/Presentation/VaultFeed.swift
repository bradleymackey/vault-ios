import Foundation
import FoundationExtensions

/// A feed of vault items.
///
/// @mockable
@MainActor
public protocol VaultFeed {
    /// The feed should load all initial data.
    func reloadData() async

    /// Creates a new valut item.
    func create(item: VaultItem.Write) async throws

    /// An update was made to the given vault item.
    ///
    /// The feed should update this data and show the changes.
    func update(id: Identifier<VaultItem>, item: VaultItem.Write) async throws

    func delete(id: Identifier<VaultItem>) async throws
}
