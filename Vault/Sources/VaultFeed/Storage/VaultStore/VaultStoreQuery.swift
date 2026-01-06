import Foundation
import FoundationExtensions

public struct VaultStoreQuery: Sendable, Equatable {
    /// Filter items by the given query string.
    ///
    /// Using `nil` equates to not querying by text and won't filter items by a search query.
    public var filterText: String?

    /// Filter items by the given tags.
    ///
    /// Require that the item includes **any** of these search tags.
    public var filterTags: Set<Identifier<VaultItemTag>>

    public init(filterText: String? = nil, filterTags: Set<Identifier<VaultItemTag>> = []) {
        self.filterText = filterText
        self.filterTags = filterTags
    }
}
