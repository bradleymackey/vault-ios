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
}

extension Publisher where Output: Equatable, Output: Sendable {
    public func expect(
        firstValues: [Output],
        timeout: Duration? = nil,
        sourceLocation: SourceLocation = .__here(),
        // swiftlint:disable all
        when actions: sending @escaping () async throws -> Void
        // swiftlint:enable all
    ) async throws {
        var cancellable: AnyCancellable?
        defer { cancellable?.cancel() }

        let pending = PendingValue<Void>()

        let collectedValues = Atomic<[Output]>(initialValue: [])
        cancellable = prefix(firstValues.count).sink { _ in
            Task { await pending.fulfill() }
        } receiveValue: { value in
            collectedValues.modify {
                $0.append(value)
            }
        }

        Task {
            try await actions()
        }

        try await pending.awaitValue(timeout: timeout)
        #expect(collectedValues.value == firstValues, sourceLocation: sourceLocation)
    }
}
