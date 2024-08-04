import Foundation
import FoundationExtensions

public struct VaultStoreQuery: Sendable, Equatable {
    /// The order that items will be returned.
    public var sortOrder: VaultStoreSortOrder

    /// Filter items by the given query string.
    ///
    /// Using `nil` equates to not querying by text and won't filter items by a search query.
    public var filterText: String?

    /// Filter items by the given tags.
    ///
    /// Require that the item includes **any** of these search tags.
    public var filterTags: Set<Identifier<VaultItemTag>>

    init(sortOrder: VaultStoreSortOrder, filterText: String? = nil, filterTags: Set<Identifier<VaultItemTag>> = []) {
        self.sortOrder = sortOrder
        self.filterText = filterText
        self.filterTags = filterTags
    }
}
