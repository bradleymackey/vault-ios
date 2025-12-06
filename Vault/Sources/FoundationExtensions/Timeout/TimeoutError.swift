import Foundation

public struct TimeoutError: Error, LocalizedError {
    /// Identifies this timeout so we can distinguish where a timeout originated from.
    public let id: UUID
    /// The reason for the timeout.
    public let description: String?
    /// When the timeout occurred.
    public let occurred: Date = .init()

    public init(id: UUID = UUID(), description: String? = nil) {
        self.id = id
        self.description = description
    }

    public var errorDescription: String? {
        description ?? "The operation timed out."
    }
}
