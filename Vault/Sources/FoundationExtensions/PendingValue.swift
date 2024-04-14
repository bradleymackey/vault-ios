import Combine
import Foundation

/// Asynchronously return a value when a signal is triggered.
public actor PendingValue<Output> {
    private var stream: AsyncThrowingStream<Output, any Error>?
    private var valuePipeline: ValuePipeline = .init()
    /// Internal pipeline listener.
    private var pipelineListener: AnyCancellable?
    /// Last remembered value, used if the value is fulfilled before
    /// we await the given value.
    private var lastValue: Result<Output, any Error>?

    public init() {}
}

// MARK: - API

extension PendingValue {
    /// Returns `true` if waiting on `waitToProduce` at this moment.
    public var isWaiting: Bool {
        stream != nil
    }

    /// Cancel the `waitToProduce`, causing it to throw a `CancellationError`.
    public func cancel() {
        valuePipeline.cancel()
    }

    /// If pending, produces the value, causing `waitToProduce` to return it's value immediately.
    public func fulfill(_ value: Output) {
        lastValue = .success(value)
        valuePipeline.finish(result: .success(value))
    }

    /// Produces an error to cause `waitToForValue` to throw.
    public func reject(error: any Error) {
        lastValue = .failure(error)
        valuePipeline.finish(result: .failure(error))
    }

    public struct AlreadyWaitingError: Error {}

    public struct MissingValueError: Error {}

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
            stream = nil
        }

        var listener: AnyCancellable?
        defer { listener?.cancel() }
        stream = AsyncThrowingStream { continuation in
            listener = valuePipeline.publisher().sink { completion in
                switch completion {
                case let .failure(error):
                    continuation.finish(throwing: error)
                case .finished:
                    continuation.finish()
                }
            } receiveValue: { value in
                continuation.yield(value)
            }
        }

        for try await value in stream! {
            return value
        }
        throw MissingValueError()
    }
}

// MARK: - Internal

extension PendingValue {
    private struct ValuePipeline {
        private var subject: PassthroughSubject<Output, any Error>

        init() {
            subject = .init()
        }

        func cancel() {
            subject.send(completion: .failure(CancellationError()))
        }

        func finish(result: Result<Output, any Error>) {
            switch result {
            case let .success(value):
                subject.send(value)
                subject.send(completion: .finished)
            case let .failure(err):
                subject.send(completion: .failure(err))
            }
        }

        func publisher() -> AnyPublisher<Output, any Error> {
            subject.eraseToAnyPublisher()
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
