import Foundation

public struct PresentationError: Error, Equatable {
    public var userVisibleDescription: String
    public var debugDescription: String

    public init(userVisibleDescription: String, debugDescription: String) {
        self.userVisibleDescription = userVisibleDescription
        self.debugDescription = debugDescription
    }
}
