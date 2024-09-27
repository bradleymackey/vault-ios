import Foundation

public struct TimeoutError: Error, LocalizedError {
    /// When the timeout occurred.
    public let occurred: Date = .init()

    public init() {}

    public var errorDescription: String? {
        "The operation timed out."
    }
}
