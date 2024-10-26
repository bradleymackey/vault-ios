import Foundation
import FoundationExtensions
import os
import TestHelpers
import Testing

@Suite("Task Continuation Tests", .timeLimit(.minutes(1)))
struct TaskContinuationTests {
    @Test
    func runsTaskToCompletion() async throws {
        try await confirmation(expectedCount: 1) { confirmation in
            try await Task.continuation {
                confirmation.confirm()
            }
        }
    }

    @Test
    func cancelsBeforeTaskRuns() async throws {
        let pending1 = Pending.signal()
        let waiter = TaskCancellationWaiter()
        let outer = Task.detached {
            await pending1.fulfill()
            await waiter.waitForTaskCancellation()
            let result = try await Task.continuation {
                Issue.record("Should not reach here, task should never start.")
                return 100
            }
            Issue.record("Cancellation error should be thrown from continuation")
            return result
        }
        try await pending1.wait() // wait for task to start

        outer.cancel()

        await #expect(throws: CancellationError.self, performing: {
            try await outer.result.get()
        })
    }
}
