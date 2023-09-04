import Foundation

/// Represents a cache that stores code details.
/// If a given code changes, it's entry in this cache will need to be invalidated.
public protocol CodeDetailCache {
    func invalidateCache(id: UUID)
}
