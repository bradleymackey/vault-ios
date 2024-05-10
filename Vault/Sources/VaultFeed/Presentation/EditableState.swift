import Foundation

public protocol EditableState: Equatable {
    /// Is the state of this edit totally valid?
    var isValid: Bool { get }
}
