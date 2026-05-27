import Foundation
import Testing
@testable import TestHelpers

@Suite(.trackLeaks)
struct LeakTrackingTests {
    @Test
    func cleanDeallocation_recordsNoIssue() {
        _ = trackForMemoryLeaks(Probe())
    }

    @Test
    func retainedInstance_recordsIssue() async throws {
        let probe = Probe()
        await withKnownIssue {
            try await runInIsolatedScope {
                _ = trackForMemoryLeaks(probe)
            }
        }
        _ = probe
    }

    private func runInIsolatedScope(_ body: () async throws -> Void) async throws {
        let tracker = LeakTracker()
        try await LeakTracker.$current.withValue(tracker) {
            try await body()
        }
        tracker.verify()
    }
}

// MARK: - Helpers

extension LeakTrackingTests {
    fileprivate final class Probe {}
}
