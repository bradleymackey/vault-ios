import Foundation
import FoundationExtensions
import TestHelpers
import Testing

@Suite("Task Background Tests", .timeLimit(.minutes(1)))
struct TaskBackgroundTests {
    @Test
    func runsTaskToCompletion() async throws {
        try await confirmation(expectedCount: 1) { confirmation in
            try await Task.background {
                confirmation.confirm()
            }
        }
    }

    @Test
    func rethrowsCancellation() async throws {
        let pending1 = Pending.signal()
        let outer = Task.detached {
            try await Task.background {
                await pending1.fulfill()
                try await suspendForever()
            }
            Issue.record("Should not reach here: Task.background should throw CancellationError")
        }

        try await pending1.wait() // wait for task to start

        outer.cancel()

        await #expect(throws: CancellationError.self) {
            try await outer.result.get()
        }
    }
}
