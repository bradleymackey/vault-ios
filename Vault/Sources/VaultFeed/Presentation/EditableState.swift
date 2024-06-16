import Foundation

public protocol EditableState: Equatable, Sendable {
    /// Is the state of this edit totally valid?
    var isValid: Bool { get }
}
