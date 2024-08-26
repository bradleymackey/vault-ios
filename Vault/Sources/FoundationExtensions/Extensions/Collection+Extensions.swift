import Foundation

extension Collection {
    public var isNotEmpty: Bool {
        !isEmpty
    }
}

extension RandomAccessCollection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    /// - complexity: O(1)
    public subscript(safeIndex index: Index) -> Element? {
        guard index >= startIndex, index < endIndex else {
            return nil
        }
        return self[index]
    }
}
