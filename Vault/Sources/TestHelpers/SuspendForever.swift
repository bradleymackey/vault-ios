import Foundation

/// Swift async function that will suspend forever.
///
/// This is achieved by awaiting on a stream that never yields any values.
///
/// - throws: `CancellationError` if the task this is in is cancelled.
public func suspendForever() async throws {
    let stream = AsyncStream<Never> { _ in }
    for await _ in stream {
        fatalError("Unreachable")
    }
    // The stream will only exit without a value in the case that it's been cancelled.
    // Propagate the cancellation.
    throw CancellationError()
}
