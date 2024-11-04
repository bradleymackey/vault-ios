import Foundation
import FoundationExtensions
import TestHelpers
import Testing
import VaultCore

enum IntervalTimerTests {
    struct MockTests {
        let sut = IntervalTimerMock()

        @Test(arguments: [-1, 0, 0.1, 0.2, 1])
        func wait_doesNotFulfillImmediately(duration _: Double) async throws {
            try await confirmation(timeout: .seconds(1), expectedCount: 0) { confirmation in
                try await sut.wait(for: 0.1)
                confirmation.confirm()
            }
        }

        @Test(arguments: [-1, 0, 0.1])
        func wait_fulfillsWhenFinishTimerIsCalled(duration _: Double) async throws {
            let pendingStart = Pending.signal()
            let completed = Pending.signal()
            Task {
                try await confirmation(timeout: .seconds(1), expectedCount: 0) { _ in
                    await pendingStart.fulfill()
                    try await sut.wait(for: 0.1)
                    await completed.fulfill()
                }
            }

            try await pendingStart.wait(timeout: .seconds(1))
            await Task.yield()

            await sut.finishTimer()

            try await completed.wait(timeout: .seconds(1))
        }

        @Test(arguments: [-1, 0, 0.1, 0.2, 1])
        func waitWithTolerance_doesNotFulfillImmediately(duration _: Double) async throws {
            try await confirmation(timeout: .seconds(1), expectedCount: 0) { confirmation in
                try await sut.wait(for: 0.1, tolerance: 0.1)
                confirmation.confirm()
            }
        }

        @Test(arguments: [-1, 0, 0.1])
        func waitWithTolerance_fulfillsWhenFinishTimerIsCalled(duration _: Double) async throws {
            let pendingStart = Pending.signal()
            let completed = Pending.signal()
            Task {
                try await confirmation(timeout: .seconds(1), expectedCount: 0) { _ in
                    await pendingStart.fulfill()
                    try await sut.wait(for: 0.1, tolerance: 0.1)
                    await completed.fulfill()
                }
            }

            try await pendingStart.wait(timeout: .seconds(1))
            await Task.yield()

            await sut.finishTimer()

            try await completed.wait(timeout: .seconds(1))
        }

        @Test
        func wait_multipleWaitsCanCompleteIndependently() async throws {
            try await confirmation { confirmation in
                let started = Pending.signal()
                Task {
                    await started.fulfill()
                    try await sut.wait(for: 10)
                    try await sut.wait(for: 10)
                    try await sut.wait(for: 10)
                    confirmation.confirm()
                }

                try await started.wait()
                await sut.finishTimer(at: 0)
                await sut.finishTimer(at: 1)
                await sut.finishTimer(at: 2)
            }
        }

        @Test
        func schedule_completingTimerFinishesDuringAwait() async throws {
            try await confirmation(timeout: .seconds(1)) { confirmation in
                _ = sut.schedule(wait: 10) {
                    confirmation.confirm()
                }
                await sut.finishTimer()
            }
        }

        @Test
        func schedule_multipleSchedulesCanCompleteIndependently() async throws {
            try await confirmation(timeout: .seconds(1), expectedCount: 2 + 3 + 5) { confirmation in
                _ = sut.schedule(wait: 10) {
                    confirmation.confirm(count: 2)
                }
                _ = sut.schedule(wait: 10) {
                    confirmation.confirm(count: 3)
                }
                _ = sut.schedule(wait: 10) {
                    confirmation.confirm(count: 5)
                }
                await sut.finishTimer(at: 0)
                await sut.finishTimer(at: 1)
                await sut.finishTimer(at: 2)
            }
        }
    }

    struct ImplTests {
        let sut = IntervalTimerImpl()

        @Test
        func wait_negativeCompletesImmediately() async throws {
            try await confirmation(timeout: .seconds(1)) { confirmation in
                try await sut.wait(for: -20)
                confirmation.confirm()
            }
        }

        @Test
        func wait_publishesAfterWait() async throws {
            try await confirmation(timeout: .seconds(1)) { confirmation in
                try await sut.wait(for: 0.5)
                confirmation.confirm()
            }
        }

        @Test
        func wait_doesNotPublishBeforeWait() async throws {
            try await confirmation(timeout: .seconds(1), expectedCount: 0) { confirmation in
                try await sut.wait(for: 10)
                confirmation.confirm()
            }
        }

        @Test
        func waitWithTolerance_publishesAfterWait() async throws {
            try await confirmation(timeout: .seconds(1)) { confirmation in
                try await sut.wait(for: 0.2, tolerance: 0.2)
                confirmation.confirm()
            }
        }

        @Test
        func waitWithTolerance_doesNotPublishBeforeWait() async throws {
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
            let task = sut.schedule(priority: .medium, wait: 0.5, tolerance: 0.5) {
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
                    _ = sut.schedule(wait: 0.5) { @MainActor in
                        dispatchPrecondition(condition: .onQueue(.main))
                        thing.time = 200
                        continuation.resume()
                    }
                }
            }
        }
    }
}
