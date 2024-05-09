import Foundation

/// Represents a cache that vault item details in *any way it needs*.
/// If a given vault item changes, it's entry in this cache will need to be invalidated.
///
/// @mockable(history: invalidateVaultItemDetailCache = true)
public protocol VaultItemCache {
    func invalidateVaultItemDetailCache(forVaultItemWithID id: UUID)
}
