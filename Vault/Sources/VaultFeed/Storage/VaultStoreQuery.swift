import Foundation
import FoundationExtensions

public struct VaultStoreQuery: Sendable, Equatable {
    public enum SortOrder: Equatable, Sendable {
        /// Uses a sort order that's best suited for users.
        ///
        /// It sorts by the following values in this order: relativeOrder, createdDate (reversed).
        case relativeOrder
        /// Respects only the created date of the item, more useful for debugging, as it will return items in the
        /// same order that they were created.
        case createdDate
    }

    /// The order that items will be returned.
    public var sortOrder: SortOrder

    /// Require that the item includes this search text.
    ///
    /// Using `nil` equates to not querying by text and won't filter items by a search query.
    public var searchText: String?

    /// Require that the item includes **all** these search tags.
    public var tags: Set<Identifier<VaultItemTag>>

    init(sortOrder: SortOrder, searchText: String? = nil, tags: Set<Identifier<VaultItemTag>> = []) {
        self.sortOrder = sortOrder
        self.searchText = searchText
        self.tags = tags
    }
}
