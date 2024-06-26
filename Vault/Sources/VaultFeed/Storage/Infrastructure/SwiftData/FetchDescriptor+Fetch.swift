import Foundation
import SwiftData

extension FetchDescriptor {
    /// A descriptor that returns all items of the given type.
    ///
    /// Uses an always-true predicate to match all items.
    static func all(sortBy: [SortDescriptor<T>] = []) -> Self {
        FetchDescriptor(predicate: #Predicate { _ in true }, sortBy: sortBy)
    }
}
