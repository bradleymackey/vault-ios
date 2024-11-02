import Foundation
import FoundationExtensions

/// Represents a cache that vault item details in *any way it needs*.
/// If a given vault item changes, it's entry in this cache will need to be invalidated.
///
/// @mockable
public protocol VaultItemCache: Sendable {
    /// Removes all items from the cache.
    ///
    /// - Important: Note that this is very agressive and should be avoided if at all possible.
    /// It is useful in app extensions when we want to make sure the local state it is receving is fresh.
    func vaultItemCacheClearAll() async

    /// Removes a specific item from the cache.
    ///
    /// This is granualar and recommended when we know a single given item has changed.
    func vaultItemCacheClear(forVaultItemWithID id: Identifier<VaultItem>) async
}
