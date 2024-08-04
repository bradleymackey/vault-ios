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

    /// Filter items by the given query string.
    ///
    /// Using `nil` equates to not querying by text and won't filter items by a search query.
    public var filterText: String?

    /// Filter items by the given tags.
    ///
    /// Require that the item includes **any** of these search tags.
    public var filterTags: Set<Identifier<VaultItemTag>>

    init(sortOrder: SortOrder, filterText: String? = nil, filterTags: Set<Identifier<VaultItemTag>> = []) {
        self.sortOrder = sortOrder
        self.filterText = filterText
        self.filterTags = filterTags
    }
}
