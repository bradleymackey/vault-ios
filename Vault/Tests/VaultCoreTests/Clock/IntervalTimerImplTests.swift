import Foundation
import FoundationExtensions
import TestHelpers
import Testing
import VaultCore

struct IntervalTimerImplTests {
    let sut = IntervalTimerImpl()

    @Test
    func waitAsync_negativeCompletesImmediately() async throws {
        try await confirmation(timeout: .seconds(1)) { confirmation in
            try await sut.wait(for: -20)
            confirmation.confirm()
        }
    }

    @Test
    func waitAsync_publishesAfterWait() async throws {
        try await confirmation(timeout: .seconds(1)) { confirmation in
            try await sut.wait(for: 0.5)
            confirmation.confirm()
        }
    }

    @Test
    func waitAsync_doesNotPublishBeforeWait() async throws {
        try await confirmation(timeout: .seconds(1), expectedCount: 0) { confirmation in
            try await sut.wait(for: 10)
            confirmation.confirm()
        }
    }

    @Test
    func waitAsyncWithTolerance_publishesAfterWait() async throws {
        try await confirmation(timeout: .seconds(1)) { confirmation in
            try await sut.wait(for: 0.2, tolerance: 0.2)
            confirmation.confirm()
        }
    }

    @Test
    func waitAsyncWithTolerance_doesNotPublishBeforeWait() async throws {
        try await confirmation(timeout: .seconds(1), expectedCount: 0) { confirmation in
            try await sut.wait(for: 10, tolerance: 0.5)
            confirmation.confirm()
        }
    }

    @Test(arguments: [101, 102, 103])
    func schedule_publishesAfterWait(expectedValue: Int) async throws {
        let task = sut.schedule(wait: 0.5) {
            expectedValue
        }

        let value = try await task.value
        #expect(value == expectedValue)
    }

    @Test(arguments: [101, 102, 103])
    func schedule_publishesAfterWaitWithTolerance(expectedValue: Int) async throws {
        let task = sut.schedule(wait: 0.5, tolerance: 0.5) {
            expectedValue
        }

        let value = try await task.value
        #expect(value == expectedValue)
    }

    @Test
    func schedule_isolatesWorkToGlobalActor() async throws {
        @MainActor
        class Thing {
            var time = 100
        }
        let thing = Thing()

        await withCheckedContinuation { continuation in
            Task.detached(priority: .background) {
                dispatchPrecondition(condition: .notOnQueue(.main))
                sut.schedule(wait: 0.5) { @MainActor in
                    dispatchPrecondition(condition: .onQueue(.main))
                    thing.time = 200
                    continuation.resume()
                }
            }
        }
    }
}
