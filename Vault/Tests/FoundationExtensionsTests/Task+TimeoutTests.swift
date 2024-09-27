import Foundation
import FoundationExtensions
import TestHelpers
import Testing

struct TaskTimeoutTests {
    @Test
    func timeoutReturnsTimeoutError() async throws {
        let t = Task.withTimeout(delay: .milliseconds(100)) {
            try await suspendForever()
        }
        try await Task.sleep(for: .milliseconds(500))
        await #expect(throws: TimeoutError.self, performing: {
            try await t.value
        })
    }

    @Test
    func cancelledReturnsCancelledError() async throws {
        let t = Task.withTimeout(delay: .milliseconds(500)) {
            try await suspendForever()
        }
        t.cancel()

        await #expect(throws: CancellationError.self, performing: {
            try await t.value
        })
    }

    @Test
    func returnsValue() async throws {
        let pending = PendingValue<Int>()
        let t = Task.withTimeout(delay: .seconds(10)) {
            try await pending.awaitValue()
        }
        try await Task.sleep(for: .milliseconds(100))
        await pending.fulfill(101)
        let value = try await t.value

        #expect(value == 101)
    }
}
