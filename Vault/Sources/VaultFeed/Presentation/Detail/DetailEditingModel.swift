import Combine
import Foundation

/// Manages the state when editing a particular model, tracking if the edits are dirty or not.
public struct DetailEditingModel<T: EditableState> {
    public var detail: T
    public private(set) var initialDetail: T
    private let isInitiallyDirty: Bool
    private var overrideIsDirty: Bool

    public init(detail: T, isInitiallyDirty: Bool = false) {
        initialDetail = detail
        self.detail = detail
        overrideIsDirty = isInitiallyDirty
        self.isInitiallyDirty = isInitiallyDirty
    }

    public var isValid: Bool {
        detail.isValid
    }

    public var isDirty: Bool {
        if overrideIsDirty {
            true
        } else {
            detail != initialDetail
        }
    }

    public mutating func restoreInitialState() {
        overrideIsDirty = isInitiallyDirty
        detail = initialDetail
    }

    public mutating func didPersist() {
        overrideIsDirty = false
        initialDetail = detail
    }
}
