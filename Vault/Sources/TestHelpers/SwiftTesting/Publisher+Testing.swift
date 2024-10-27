import Combine
import Foundation
import FoundationExtensions
import Testing

extension Publisher {
    /// Creates a testing `confirmation` that a publisher will produce the given number of elements.
    public func expect(
        valueCount: Int,
        sourceLocation _: SourceLocation = .__here(),
        when actions: () async throws -> Void
    ) async throws {
        var cancellable: AnyCancellable?
        defer { cancellable?.cancel() }
        try await confirmation(expectedCount: valueCount) { confirmation in
            cancellable = sink { _ in
                // noop
            } receiveValue: { _ in
                confirmation.confirm()
            }
            try await actions()
        }
    }

    @MainActor
    public func waitForFirstValue(timeout: Duration = .seconds(1)) async throws {
        var cancellable: AnyCancellable?
        defer { cancellable?.cancel() }

        let signal = Pending.signal()

        cancellable = sink { _ in
            // noop
        } receiveValue: { _ in
            Task { await signal.fulfill() }
        }

        try await signal.wait(timeout: timeout)
    }
}

extension Publisher where Output: Equatable, Output: Sendable {
    @MainActor
    public func expect(
        firstValues: [Output],
        timeout: Duration = .seconds(1),
        sourceLocation: SourceLocation = .__here(),
        when actions: sending @escaping () async throws -> Void
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
        Task { try await actions() }

        // Wait for all the values to be recieved.
        try await signal.wait(timeout: timeout)
        #expect(collectedValues.value == firstValues, sourceLocation: sourceLocation)
    }
}
