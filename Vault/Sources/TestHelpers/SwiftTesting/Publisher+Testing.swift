import Combine
import Foundation
import Testing

extension Publisher where Failure == Never {
    /// Creates a testing `confirmation` that a
    public func expect(eventCount: Int, actions: () async throws -> Void) async throws {
        var cancellable: AnyCancellable?
        try await confirmation(expectedCount: eventCount) { confirmation in
            cancellable = sink { _ in
                confirmation.confirm()
            }
            try await actions()
        }
        cancellable?.cancel()
    }
}
