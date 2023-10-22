import Combine
import Foundation

/// Manages the state when editing a particular model, tracking if the edits are dirty or not.
public struct DetailEditingModel<T: Equatable> {
    public var detail: T
    public private(set) var initialDetail: T

    public init(detail: T) {
        initialDetail = detail
        self.detail = detail
    }

    public var isDirty: Bool {
        detail != initialDetail
    }

    public mutating func restoreInitialState() {
        detail = initialDetail
    }

    public mutating func didPersist() {
        initialDetail = detail
    }
}
