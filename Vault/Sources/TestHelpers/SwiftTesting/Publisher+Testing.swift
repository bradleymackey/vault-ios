import Combine
import Foundation
import FoundationExtensions
import Testing

extension Publisher {
    /// Creates a testing `confirmation` that a publisher will produce the given number of elements.
    @MainActor
    public func expect(
        valueCount: Int,
        sourceLocation: SourceLocation = #_sourceLocation,
        when actions: () async throws -> Void,
    ) async throws {
        var cancellable: AnyCancellable?
        defer { cancellable?.cancel() }
        try await confirmation(expectedCount: valueCount, sourceLocation: sourceLocation) { confirmation in
            cancellable = sink { _ in
                // noop
            } receiveValue: { _ in
                confirmation.confirm()
            }
            try await actions()
        }
    }
}

extension Publisher where Output: Equatable, Output: Sendable {
    @MainActor
    public func expect(
        firstValues: [Output],
        timeout: Duration = .seconds(1),
        sourceLocation: SourceLocation = #_sourceLocation,
        when actions: sending @isolated(any) @escaping () async throws -> Void,
    ) async throws {
        var cancellable: AnyCancellable?
        defer { cancellable?.cancel() }

        let signal = Pending.signal()

        let collectedValues = SharedMutex<[Output]>([])
        cancellable = prefix(firstValues.count).sink { _ in
            Task { await signal.fulfill() }
        } receiveValue: { value in
            collectedValues.modify {
                $0.append(value)
            }
        }

        // Concurrently run actions while we are collecting the values.
        Task.detached {
            try await actions()
            // Yield to allow some extra time for the publisher to collect the results.
            await Task.yield()
        }

        // Wait for all the values to be recieved.
        try await signal.wait(timeout: timeout)
        #expect(collectedValues.value == firstValues, sourceLocation: sourceLocation)
    }
}

extension Publisher {
    /// Collects the first *n* elements that are output.
    public func collectFirst(_ count: Int) -> AnyPublisher<[Output], Failure> {
        collect(count)
            .first()
            .eraseToAnyPublisher()
    }
}

extension Published.Publisher {
    /// Collect the next *n* elements that are output, ignoring the first result
    public func collectNext(_ count: Int) -> AnyPublisher<[Output], Never> {
        dropFirst()
            .collect(count)
            .first()
            .eraseToAnyPublisher()
    }

    /// For @Published, this is a publisher that ignores the first element.
    public func nextElements() -> AnyPublisher<Output, Never> {
        dropFirst().eraseToAnyPublisher()
    }
}
