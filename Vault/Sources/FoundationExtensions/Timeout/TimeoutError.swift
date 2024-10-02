import Foundation

public struct TimeoutError: Error, LocalizedError {
    /// Identifies this timeout so we can distinguish where a timeout originated from.
    public let id: UUID
    /// When the timeout occurred.
    public let occurred: Date = .init()

    public init(id: UUID = UUID()) {
        self.id = id
    }

    public var errorDescription: String? {
        "The operation timed out."
    }
}
