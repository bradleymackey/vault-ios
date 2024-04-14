import Combine
import Foundation

/// Asynchronously return a value when a signal is triggered.
public actor PendingValue<Output> {
    public private(set) var isWaiting = false

    private var continuation: AsyncThrowingStream<Output, any Error>.Continuation?

    /// Last remembered value, used if the value is fulfilled before
    /// we await the given value.
    private var lastValue: Result<Output, any Error>?

    public init() {}
}

// MARK: - API

extension PendingValue {
    /// Cancel the `awaitValue`, causing it to throw a `CancellationError`.
    public func cancel() {
        continuation?.finish()
    }

    /// If pending, produces the value, causing `waitToProduce` to return it's value immediately.
    public func fulfill(_ value: Output) {
        lastValue = .success(value)
        continuation?.yield(value)
        continuation?.finish()
    }

    /// Produces an error to cause `waitToForValue` to throw.
    public func reject(error: any Error) {
        lastValue = .failure(error)
        continuation?.finish(throwing: error)
    }

    public struct AlreadyWaitingError: Error {}

    /// Wait for the production of the target value, cancelling on a Task cancellation.
    /// Yields the value when `fulfill` or `reject` is called, but waits until that moment.
    ///
    /// - throws: `CancellationError` if cancelled, `AlreadyWaitingError` if already waiting.
    public func awaitValue() async throws -> Output {
        if isWaiting {
            throw AlreadyWaitingError()
        }

        // If there's a pending value, get it.
        if let existing = lastValue {
            defer { lastValue = nil }
            return try existing.get()
        }

        // Otherwise, asynchronously wait for the production of the value.
        isWaiting = true
        defer {
            continuation = nil
            isWaiting = false
        }

        let stream = AsyncThrowingStream { continuation in
            self.continuation = continuation
        }

        for try await value in stream {
            return value
        }
        throw CancellationError()
    }
}

// MARK: - Specialisation

extension PendingValue where Output == Void {
    /// If pending, produces the value, causing `waitToProduce` to return it's value immediately.
    public func fulfill() {
        fulfill(())
    }
}
