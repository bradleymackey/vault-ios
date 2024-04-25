import Foundation
import FoundationExtensions
import TestHelpers
import XCTest

final class PendingValueTests: XCTestCase {
    enum TestError: Error {
        case testCase
        case testCase2
    }

    func test_awaitValue_throwsCancellationErrorIfCancelled() async throws {
        let sut = makeSUT()

        let exp = expectation(description: "waiting for value")
        let handle = Task {
            do {
                _ = try await sut.awaitValue()
            } catch is CancellationError {
                exp.fulfill()
            } catch {
                XCTFail("Unexpected error thrown: \(error)")
            }
        }

        handle.cancel()

        await fulfillment(of: [exp], timeout: 1.0)
    }

    func test_awaitValue_asyncFulfillsWithDifferingValuesWhenCalledMoreThanOnce() async throws {
        let sut = makeSUT()

        let result1 = await awaitValueForcingAsync(on: sut) {
            await sut.fulfill(100)
        }
        XCTAssertEqual(result1?.withAnyEquatableError(), .success(100))

        let result2 = await awaitValueForcingAsync(on: sut) {
            await sut.fulfill(101)
        }
        XCTAssertEqual(result2?.withAnyEquatableError(), .success(101))
    }

    func test_awaitValue_asyncDoesNotFulfillMoreThanOnceForSingleValue() async throws {
        let sut = makeSUT()

        let result1 = await awaitValueForcingAsync(on: sut) {
            await sut.fulfill(100)
        }
        XCTAssertEqual(result1?.withAnyEquatableError(), .success(100))

        await awaitNoValueProduced(on: sut)

        await sut.cancel()
    }

    func test_awaitValue_throwsAlreadyWaitingErrorIfAlreadyWaiting() async throws {
        let sut = makeSUT()

        let exp1 = expectation(description: "Start waiting 1")
        let task = Task {
            exp1.fulfill()
            _ = try await sut.awaitValue()
        }

        await fulfillment(of: [exp1], timeout: 1.0)

        do {
            _ = try await sut.awaitValue()
            XCTFail("Unexpected success")
        } catch is SUT.AlreadyWaitingError {
            // nice!
        } catch {
            XCTFail("Unexpected error")
        }

        task.cancel()
        await sut.cancel()
    }

    func test_fulfill_unsuspendsAwait() async throws {
        let sut = makeSUT()

        let result = await awaitValueForcingAsync(on: sut) {
            await sut.fulfill(42)
        }

        XCTAssertEqual(result?.withAnyEquatableError(), .success(42))
    }

    func test_fulfill_beforeAwaitingReturnsInitialValue() async throws {
        let sut = makeSUT()
        await sut.fulfill(42)

        let value = try await sut.awaitValue()

        XCTAssertEqual(value, 42)
    }

    func test_fulfill_remembersMostRecentValueOnly() async throws {
        let sut = makeSUT()
        await sut.fulfill(42)
        await sut.fulfill(43)
        await sut.fulfill(44)

        let value = try await sut.awaitValue()
        XCTAssertEqual(value, 44)
    }

    func test_reject_unsuspendsAwait() async throws {
        let sut = makeSUT()

        let result = await awaitValueForcingAsync(on: sut) {
            await sut.reject(error: TestError.testCase)
        }

        switch result {
        case .failure(TestError.testCase):
            break
        default:
            XCTFail("Unexpected result")
        }
    }

    func test_reject_beforeAwaitResolvesWithInitialError() async throws {
        let sut = makeSUT()
        await sut.reject(error: TestError.testCase)

        do {
            _ = try await sut.awaitValue()
            XCTFail("Error expected to be thrown.")
        } catch TestError.testCase {
            XCTAssert(true)
        } catch {
            XCTFail("Wrong thrown error type")
        }
    }

    func test_reject_resolvesWithMostRecentError() async throws {
        let sut = makeSUT()
        await sut.reject(error: TestError.testCase)
        await sut.reject(error: TestError.testCase2)

        do {
            _ = try await sut.awaitValue()
            XCTFail()
        } catch TestError.testCase2 {
            XCTAssert(true)
        } catch {
            XCTFail("Wrong thrown error type")
        }
    }

    func test_isWaiting_initiallyFalse() async {
        let sut = makeSUT()

        let isWaiting = await sut.isWaiting
        XCTAssertFalse(isWaiting)
    }

    func test_isWaiting_trueWhenWaiting() async {
        let sut = makeSUT()

        await awaitNoValueProduced(on: sut)

        let isWaiting = await sut.isWaiting
        XCTAssertTrue(isWaiting)

        await sut.cancel()
    }

    func test_isWaiting_falseWhenFulfilled() async throws {
        let sut = makeSUT()

        _ = await awaitValueForcingAsync(on: sut) {
            await sut.fulfill(42)
        }

        let isWaiting = await sut.isWaiting
        XCTAssertFalse(isWaiting)
    }

    func test_isWaiting_falseWhenRejected() async throws {
        let sut = makeSUT()

        _ = await awaitValueForcingAsync(on: sut) {
            await sut.reject(error: anyError())
        }

        let isWaiting = await sut.isWaiting
        XCTAssertFalse(isWaiting)
    }

    func test_isWaiting_falseWhenCancelled() async throws {
        let sut = makeSUT()

        _ = await awaitValueForcingAsync(on: sut) {
            await sut.cancel()
        }

        let isWaiting = await sut.isWaiting
        XCTAssertFalse(isWaiting)
    }
}

// MARK: Helpers

extension PendingValueTests {
    private typealias SUT = PendingValue<Int>

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> SUT {
        let sut = PendingValue<Int>()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func anyError() -> any Error {
        struct SomeError: Error {}
        return SomeError()
    }

    /// Forces the SUT to start awaiting before calling `action`.
    ///
    /// This ensures the last value cache is checked before any action (fulfill/reject) is called.
    /// Without this, you might acidentally call `fulfill`/`reject` before await, and thus the value will be cached.
    @MainActor
    private func awaitValueForcingAsync(on sut: SUT, action: () async -> Void) async -> Result<Int, any Error>? {
        var capturedResult: Result<Int, any Error>?
        let expStartedWaiting = expectation(description: "Started waiting")
        let expInitial = expectation(description: "waiting for value")
        Task {
            expStartedWaiting.fulfill()
            do {
                let value = try await sut.awaitValue()
                capturedResult = .success(value)
            } catch {
                capturedResult = .failure(error)
            }
            expInitial.fulfill()
        }

        // Wait for the task to start before the action, so we know that we hit the `awaitValue` call.
        await fulfillment(of: [expStartedWaiting], timeout: 1.0)

        await action()

        // Make sure we captured the result of the value that we awaited.
        await fulfillment(of: [expInitial], timeout: 1.0)

        return capturedResult
    }

    private func awaitNoValueProduced(on sut: SUT) async {
        let expNext = expectation(description: "Wait for no value")
        expNext.isInverted = true
        Task {
            _ = try await sut.awaitValue()
            expNext.fulfill()
        }
        await fulfillment(of: [expNext], timeout: 1.0)
    }
}

extension Result {
    struct AnyEquatableError: Error, Equatable {}
    func withAnyEquatableError() -> Result<Success, AnyEquatableError> {
        mapError { _ in AnyEquatableError() }
    }
}
