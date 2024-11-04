import Foundation
import FoundationExtensions

extension Observable {
    @MainActor
    public func waitForChange(
        to property: KeyPath<Self, some Any>,
        timeout: Duration? = nil,
        when action: @MainActor () async throws -> Void
    ) async throws {
        let pending = Pending.signal()
        withObservationTracking {
            _ = self[keyPath: property]
        } onChange: {
            Task { await pending.fulfill() }
        }

        try await action()

        try await pending.wait(timeout: timeout)
    }
}
