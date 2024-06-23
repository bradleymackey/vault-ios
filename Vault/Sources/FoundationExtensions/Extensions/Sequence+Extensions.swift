import Foundation

extension Sequence where Element: Hashable {
    public func reducedToSet() -> Set<Element> {
        reduce(into: Set<Element>()) { partialResult, nextItem in
            partialResult.insert(nextItem)
        }
    }
}

extension Sequence {
    public func reducedToSet<T: Hashable>(_ keyPath: KeyPath<Element, T>) -> Set<T> {
        reduce(into: Set<T>()) { partialResult, nextItem in
            partialResult.insert(nextItem[keyPath: keyPath])
        }
    }
}
