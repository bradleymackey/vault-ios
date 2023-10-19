import Combine
import Foundation

/// Asynchronously return a value when a signal is triggered.
public actor PendingValue<Output> {
    /// A one-shot publisher, on which we check it's completion.
    private var valuePipeline: PassthroughSubject<Output, any Error>?
    /// Internal pipeline listener.
    private var pipelineListener: AnyCancellable?
    /// Last remembered value, used if the value is fulfilled before
    /// we await the given value.
    private var lastValue: Result<Output, any Error>?

    public init() {}
}

// MARK: - Helpers

extension PendingValue {
    /// Returns `true` if waiting on `waitToProduce` at this moment.
    public var isWaiting: Bool {
        valuePipeline != nil
    }

    /// Cancel the `waitToProduce`, causing it to throw a `CancellationError`.
    public func cancel() {
        valuePipeline?.send(completion: .failure(CancellationError()))
    }
}

// MARK: - API

extension PendingValue {
    /// If pending, produces the value, causing `waitToProduce` to return it's value immediately.
    public func fulfill(_ value: Output) {
        lastValue = .success(value)
        valuePipeline?.send(value)
        valuePipeline?.send(completion: .finished)
    }

    /// Produces an error to cause `waitToForValue` to throw.
    public func reject(error: any Error) {
        lastValue = .failure(error)
        valuePipeline?.send(completion: .failure(error))
    }

    public struct AlreadyWaitingError: Error {}

    /// Wait for the production of the target value, cancelling on a Task cancellation.
    /// Yields the value when `produceNow` is called, but waits until that moment.
    ///
    /// - throws: `CancellationError` if cancelled, `ProductionError.alreadyWaiting` if already waiting.
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
            pipelineListener?.cancel()
            valuePipeline = nil
        }
        valuePipeline = .init()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { cont in
                guard let valuePipeline else {
                    return cont.resume(throwing: CancellationError())
                }
                self.pipelineListener = valuePipeline.sink { completed in
                    switch completed {
                    case let .failure(error):
                        cont.resume(throwing: error)
                    case .finished:
                        // already resolved with value in `recieveValue`.
                        return
                    }
                } receiveValue: { value in
                    cont.resume(returning: value)
                }
            }
        } onCancel: {
            Task {
                await valuePipeline?.send(completion: .failure(CancellationError()))
            }
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
