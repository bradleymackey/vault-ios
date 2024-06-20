import Foundation

extension Sequence where Element: Hashable {
    public func reducedToSet() -> Set<Element> {
        reduce(into: Set<Element>()) { partialResult, nextItem in
            partialResult.insert(nextItem)
        }
    }
}
