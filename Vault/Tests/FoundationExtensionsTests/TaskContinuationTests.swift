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
    func cancellationCancelsTask() async throws {
        let isStarted = Atomic(initialValue: false)

        let outer = Task.detached {
            try await Task.continuation {
                isStarted.modify { $0 = true }
                // make sure it starts first
                // then immediately cancel this task
                sleep(1)
            }
        }

        while !isStarted.value {
            try await Task.sleep(for: .milliseconds(50))
        }

        outer.cancel()
        await #expect(throws: CancellationError.self, performing: {
            try await outer.value
        })
    }

    @Test
    func cancelsBeforeTaskRuns() async throws {
        let pending1 = PendingValue<Void>()
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
        try await pending1.awaitValue() // wait for task to start

        outer.cancel()

        await #expect(throws: CancellationError.self, performing: {
            try await outer.result.get()
        })
    }
}

// MARK: - Task Cancellation waiting helpers

private typealias TaskCancellationWaiter = PendingValue<Void>

extension PendingValue where Output == Void {
    fileprivate func waitForTaskCancellation() async {
        do {
            // Awaiting a value will throw `CancellationError` when the Task it's part of is cancelled.
            try await awaitValue()
        } catch {
            guard error is CancellationError else {
                preconditionFailure("Expected a cancellation error!")
            }
        }
    }
}
