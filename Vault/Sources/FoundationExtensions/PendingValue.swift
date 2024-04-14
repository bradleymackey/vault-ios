import Foundation

/// Asynchronously return a value when a signal is triggered.
public actor PendingValue<Output> {
    /// The stream that outputs the value internally within `awaitValue`.
    private var streamContinuation: AsyncThrowingStream<Output, any Error>.Continuation?

    /// Last remembered value, used if the value is fulfilled before
    /// we await the given value.
    private var lastValue: Result<Output, any Error>?

    public init() {}
}

// MARK: - API

extension PendingValue {
    /// Whether a value is currently being waited for via `awaitValue`.
    public var isWaiting: Bool {
        streamContinuation != nil
    }

    /// Cancel the `awaitValue`, causing it to throw a `CancellationError`.
    public func cancel() {
        streamContinuation?.finish()
    }

    /// If pending, produces the value, causing `waitToProduce` to return it's value immediately.
    public func fulfill(_ value: Output) {
        lastValue = .success(value)
        streamContinuation?.yield(value)
        streamContinuation?.finish()
    }

    /// Produces an error to cause `waitToForValue` to throw.
    public func reject(error: any Error) {
        lastValue = .failure(error)
        streamContinuation?.finish(throwing: error)
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
        defer {
            streamContinuation = nil
        }

        let stream = AsyncThrowingStream { continuation in
            self.streamContinuation = continuation
        }

        if let first = try await stream.first {
            return first
        } else {
            // The stream will only exit without a value in the case that it's been cancelled.
            // Propagate the cancellation.
            throw CancellationError()
        }
    }
}

// MARK: - Specialisation

extension PendingValue where Output == Void {
    /// If pending, produces the value, causing `waitToProduce` to return it's value immediately.
    public func fulfill() {
        fulfill(())
    }
}

extension AsyncThrowingStream {
    fileprivate var first: Element? {
        get async throws {
            for try await value in self {
                return value
            }
            return nil
        }
    }
}
