import Foundation

public enum VaultStoreSortOrder: Equatable, Sendable {
    /// Uses a sort order that's best suited for users.
    ///
    /// It sorts by the following values in this order: relativeOrder, createdDate (reversed).
    case relativeOrder
    /// Respects only the created date of the item, more useful for debugging, as it will return items in the
    /// same order that they were created.
    case createdDate
}
