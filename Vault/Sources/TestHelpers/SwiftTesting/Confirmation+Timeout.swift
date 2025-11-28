import Foundation
import FoundationExtensions
import Testing

/// A `Testing.confirmation` that will throw a `TimeoutError` if the confirmation is not fulfilled within the expected
/// duration.
///
/// - Returns: Value computed from `body` or `nil` if we didn't expect fulfillment and/or the operation timed out.
public func confirmation<R: Sendable>(
    timeout: Duration,
    expectedCount: Int = 1,
    sourceLocation: Testing.SourceLocation = #_sourceLocation,
    _ body: @escaping @Sendable (Testing.Confirmation) async throws -> R,
) async throws -> R? {
    let timeoutID = UUID()
    do {
        return try await Task.withTimeout(delay: timeout, priority: .high, timeoutID: timeoutID) {
            try await confirmation(expectedCount: expectedCount, sourceLocation: sourceLocation) { confirmation in
                try await body(confirmation)
            }
        }
    } catch let error as TimeoutError where expectedCount == 0 && error.id == timeoutID {
        // ** The Confirmation timed out and this was expected **
        // - If `expectedCount == 0` we didn't want the operation to fulfill and we wanted a timeout.
        // - We ensure that the timeout originates from the continuation timeout and not from another timeout in `body`.
        return nil
    } catch {
        throw error
    }
}
