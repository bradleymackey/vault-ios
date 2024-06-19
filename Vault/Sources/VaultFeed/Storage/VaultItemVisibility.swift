import Foundation
import FoundationExtensions

public enum VaultItemVisibility: Equatable, Hashable, IdentifiableSelf, Sendable {
    /// This item is always visible in the feed and in searches.
    case always
    /// This item is only visible when searching, according to the `SearchableLevel`
    case onlySearch
}
