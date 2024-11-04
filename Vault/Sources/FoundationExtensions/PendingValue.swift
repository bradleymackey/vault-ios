import Foundation

/// Asynchronously return a value when a signal is triggered.
public actor Pending<Value: Sendable>: Identifiable {
    /// The stream that outputs the value internally within `wait`.
    private var streamContinuation: AsyncThrowingStream<Value, any Swift.Error>.Continuation?

    /// Last remembered value, used if the value is fulfilled before
    /// we await the given value.
    private var lastValue: Result<Value, any Swift.Error>?

    public nonisolated let id = UUID()

    public init() {}
}

// MARK: - API

extension Pending {
    /// Whether a value is currently being waited for via `wait`.
    public var isWaiting: Bool {
        streamContinuation != nil
    }

    /// Cancel the `wait`, causing it to throw a `CancellationError`.
    public func cancel() {
        streamContinuation?.finish()
    }

    /// If pending, produces the value, causing `wait` to return it's value immediately.
    public func fulfill(_ value: Value) {
        lastValue = .success(value)
        streamContinuation?.yield(value)
        streamContinuation?.finish()
    }

    /// Produces an error to cause `wait` to throw.
    public func reject(error: any Swift.Error) {
        lastValue = .failure(error)
        streamContinuation?.finish(throwing: error)
    }

    public enum Error: Swift.Error, Equatable {
        case alreadyWaiting
    }

    /// Wait for the production of the target value, cancelling on a Task cancellation.
    /// Yields the value when `fulfill` or `reject` is called, but waits until that moment.
    ///
    /// - throws: `CancellationError` if cancelled, `AlreadyWaitingError` if already waiting, `TimeoutError` if the
    /// given `timeout` is reached before a value is produced.
    public func wait(timeout: Duration? = nil) async throws -> Value {
        if isWaiting {
            throw Error.alreadyWaiting
        }

        // Always drop the last value after awaiting.
        // We either return it right away or we already awaited the value live (no need to get it from lastValue).
        defer { lastValue = nil }

        // If there's a pending value, get it.
        if let existing = lastValue {
            return try existing.get()
        }

        // Otherwise, asynchronously wait for the production of the value.
        defer {
            streamContinuation = nil
        }

        let stream = AsyncThrowingStream { continuation in
            self.streamContinuation = continuation
        }

        @Sendable func getValue() async throws -> Value {
            if let first = try await stream.first {
                return first
            } else {
                // The stream will only exit without a value in the case that it's been cancelled.
                // Propagate the cancellation.
                throw CancellationError()
            }
        }

        if let timeout {
            return try await Task.withTimeout(delay: timeout) {
                try await getValue()
            }
        } else {
            return try await getValue()
        }
    }
}

// MARK: - Specialisation

extension Pending where Value == Void {
    /// If pending, produces the value, causing `wait` to return it's value immediately.
    public func fulfill() {
        fulfill(())
    }

    /// When `Pending` is just being used as a signal, `Void` is the type that will be used.
    ///
    /// You don't care about a value, you just want to know when this is fulfilled.
    public static func signal() -> Self {
        .init()
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
