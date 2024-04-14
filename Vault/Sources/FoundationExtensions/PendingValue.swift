import Combine
import Foundation

/// Asynchronously return a value when a signal is triggered.
public actor PendingValue<Output> {
    private var state: PipelineState = .notWaiting
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
        state.isWaiting
    }

    /// Cancel the `waitToProduce`, causing it to throw a `CancellationError`.
    public func cancel() {
        switch state {
        case .notWaiting: break
        case let .waiting(pipeline): pipeline.cancel()
        }
    }

    /// If pending, produces the value, causing `waitToProduce` to return it's value immediately.
    public func fulfill(_ value: Output) {
        lastValue = .success(value)
        switch state {
        case .notWaiting: break
        case let .waiting(pipeline): pipeline.finish(result: .success(value))
        }
    }

    /// Produces an error to cause `waitToForValue` to throw.
    public func reject(error: any Error) {
        lastValue = .failure(error)
        switch state {
        case .notWaiting: break
        case let .waiting(pipeline): pipeline.finish(result: .failure(error))
        }
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
            state = .notWaiting
        }
        state = .waiting(.init())
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { cont in
                guard case let .waiting(valuePipeline) = state else {
                    return cont.resume(throwing: CancellationError())
                }
                self.pipelineListener = valuePipeline.publisher().sink { completed in
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
                await self.cancel()
            }
        }
    }
}

// MARK: - Internal

extension PendingValue {
    private enum PipelineState {
        case notWaiting
        case waiting(ValuePipeline)

        var isWaiting: Bool {
            switch self {
            case .notWaiting: false
            case .waiting: true
            }
        }
    }

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
