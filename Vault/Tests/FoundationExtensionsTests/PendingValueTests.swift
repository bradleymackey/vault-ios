import Foundation
import FoundationExtensions
import TestHelpers
import Testing

struct PendingValueTests {
    enum TestError: Error {
        case testCase
        case testCase2
    }

    private typealias SUT = PendingValue<Int>
    private let sut = SUT()

    @Test
    func awaitValue_throwsCancellationErrorIfCancelled() async throws {
        try await confirmation { confirmation in
            let startedWaiting = PendingValue<Void>()
            let finishedWaiting = PendingValue<Void>()
            let task = Task.detached {
                await startedWaiting.fulfill()
                do {
                    _ = try await sut.awaitValue()
                } catch is CancellationError {
                    confirmation.confirm()
                }
                await finishedWaiting.fulfill()
            }

            try await startedWaiting.awaitValue()

            task.cancel()

            try await finishedWaiting.awaitValue()
        }
    }

    @Test
    func awaitValue_asyncFulfillsWithDifferingValuesWhenCalledMoreThanOnce() async throws {
        let result1 = try await awaitValueForcingAsync(on: sut) {
            await sut.fulfill(100)
        }
        #expect(result1.withAnyEquatableError() == .success(100))

        let result2 = try await awaitValueForcingAsync(on: sut) {
            await sut.fulfill(101)
        }
        #expect(result2.withAnyEquatableError() == .success(101))
    }

    @Test
    func awaitValue_asyncDoesNotFulfillMoreThanOnceForSingleValue() async throws {
        let result1 = try await awaitValueForcingAsync(on: sut) {
            await sut.fulfill(100)
        }
        #expect(result1.withAnyEquatableError() == .success(100))

        await awaitNoValueProduced(on: sut)

        await sut.cancel()
    }

    @Test
    func awaitValue_throwsAlreadyWaitingErrorIfAlreadyWaiting() async throws {
        var task: Task<Void, any Error>?
        await withCheckedContinuation { continutation in
            task = Task.detached {
                continutation.resume()
                _ = try await sut.awaitValue()
            }
        }

        await #expect(throws: SUT.AlreadyWaitingError.self, performing: {
            _ = try await sut.awaitValue()
        })

        task?.cancel()
        await sut.cancel()
    }

    @Test
    func awaitValue_timeoutFulfillsWithError() async throws {
        await #expect(throws: TimeoutError.self, performing: {
            _ = try await sut.awaitValue(timeout: .nanoseconds(1))
        })

        await sut.cancel()
    }

    @Test
    func fulfill_unsuspendsAwait() async throws {
        let result = try await awaitValueForcingAsync(on: sut) {
            await sut.fulfill(42)
        }

        #expect(result.withAnyEquatableError() == .success(42))
    }

    @Test
    func fulfill_beforeAwaitingReturnsInitialValue() async throws {
        await sut.fulfill(42)

        let value = try await sut.awaitValue()

        #expect(value == 42)
    }

    @Test
    func fulfill_remembersMostRecentValueOnly() async throws {
        await sut.fulfill(42)
        await sut.fulfill(43)
        await sut.fulfill(44)

        let value = try await sut.awaitValue()
        #expect(value == 44)
    }

    @Test
    func reject_unsuspendsAwait() async throws {
        let result = try await awaitValueForcingAsync(on: sut) {
            await sut.reject(error: TestError.testCase)
        }

        #expect(throws: TestError.testCase, performing: {
            try result.get()
        })
    }

    @Test
    func reject_beforeAwaitResolvesWithInitialError() async throws {
        await sut.reject(error: TestError.testCase)

        await #expect(throws: TestError.testCase, performing: {
            _ = try await sut.awaitValue()
        })
    }

    @Test
    func reject_resolvesWithMostRecentError() async throws {
        await sut.reject(error: TestError.testCase)
        await sut.reject(error: TestError.testCase2)

        await #expect(throws: TestError.testCase2, performing: {
            _ = try await sut.awaitValue()
        })
    }

    @Test
    func isWaiting_initiallyFalse() async {
        let isWaiting = await sut.isWaiting
        #expect(!isWaiting)
    }

    @Test
    func isWaiting_trueWhenWaiting() async throws {
        let waitForTaskStart = PendingValue<Void>()
        Task.detached {
            await waitForTaskStart.fulfill()
            _ = try await sut.awaitValue()
        }

        try await waitForTaskStart.awaitValue()

        let isWaiting = await sut.isWaiting
        #expect(isWaiting)

        await sut.cancel()
    }

    @Test
    func isWaiting_falseWhenFulfilled() async throws {
        _ = try await awaitValueForcingAsync(on: sut) {
            await sut.fulfill(42)
        }

        let isWaiting = await sut.isWaiting
        #expect(!isWaiting)
    }

    @Test
    func isWaiting_falseWhenRejected() async throws {
        _ = try await awaitValueForcingAsync(on: sut) {
            await sut.reject(error: TestError.testCase)
        }

        let isWaiting = await sut.isWaiting
        #expect(!isWaiting)
    }

    @Test
    func isWaiting_falseWhenCancelled() async throws {
        _ = try await awaitValueForcingAsync(on: sut) {
            await sut.cancel()
        }

        let isWaiting = await sut.isWaiting
        #expect(!isWaiting)
    }
}

// MARK: Helpers

extension PendingValueTests {
    /// Forces the SUT to start awaiting before calling `action`.
    ///
    /// This ensures the last value cache is checked before any action (fulfill/reject) is called.
    /// Without this, you might acidentally call `fulfill`/`reject` before await, and thus the value will be cached.
    private func awaitValueForcingAsync(
        on sut: SUT,
        action: () async -> Void
    ) async throws -> Result<Int, any Error> {
        let startedWaiting = PendingValue<Void>()
        let finishedWaiting = PendingValue<Void>()

        var result: Result<Int, any Error>?
        let task = Task.detached(priority: .background) {
            await startedWaiting.fulfill()
            do {
                let value = try await sut.awaitValue()
                result = .success(value)
            } catch {
                result = .failure(error)
            }
            await finishedWaiting.fulfill()
        }

        try await startedWaiting.awaitValue(timeout: .seconds(1))
        await Task.yield()

        await action()

        try await finishedWaiting.awaitValue(timeout: .seconds(1))

        task.cancel()
        return try #require(result)
    }

    private func awaitNoValueProduced(on sut: SUT) async {
        // If no value is produced, this will timeout.
        await #expect(throws: TimeoutError.self, performing: {
            try await sut.awaitValue(timeout: .seconds(1))
        })
    }
}

extension Result {
    struct AnyEquatableError: Error, Equatable {}
    func withAnyEquatableError() -> Result<Success, AnyEquatableError> {
        mapError { _ in AnyEquatableError() }
    }
}
