import Foundation
import FoundationExtensions
import TestHelpers
import XCTest

final class PendingValueTests: XCTestCase {
    enum TestError: Error {
        case testCase
        case testCase2
    }

    func test_fulfill_unsuspendsAwait() async throws {
        let sut = makeSUT()

        let exp = expectation(description: "waiting for value")
        Task {
            let result = try await sut.awaitValue()
            XCTAssertEqual(result, 42)
            exp.fulfill()
        }
        Task {
            try await Task.sleep(for: .milliseconds(100))
            await sut.fulfill(42)
        }

        await fulfillment(of: [exp], timeout: 1.0)
    }

    func test_reject_unsuspendsAwait() async throws {
        let sut = makeSUT()
        let exp = expectation(description: "waiting for value")
        Task {
            defer { exp.fulfill() }
            do {
                _ = try await sut.awaitValue()
                XCTFail()
            } catch {
                XCTAssert(error is TestError)
            }
        }
        Task {
            try await Task.sleep(for: .milliseconds(100))
            await sut.reject(error: TestError.testCase)
        }

        await fulfillment(of: [exp], timeout: 1.0)
    }

    func test_fulfill_beforeAwaitingReturnsInitialValue() async throws {
        let sut = makeSUT()
        await sut.fulfill(42)
        let exp = expectation(description: "Produces")
        Task {
            defer { exp.fulfill() }
            let value = try await sut.awaitValue()
            XCTAssertEqual(value, 42)
        }

        await fulfillment(of: [exp], timeout: 1.0)
    }

    func test_fulfill_remembersMostRecentValueOnly() async throws {
        let sut = makeSUT()
        await sut.fulfill(42)
        await sut.fulfill(43)
        await sut.fulfill(44)

        let exp = expectation(description: "Produces")
        Task {
            defer { exp.fulfill() }
            let value = try await sut.awaitValue()
            // The most recent value.
            XCTAssertEqual(value, 44)
        }

        await fulfillment(of: [exp], timeout: 1.0)
    }

    func test_reject_beforeAwaitResolvesWithInitialError() async throws {
        let sut = makeSUT()
        await sut.reject(error: TestError.testCase)

        let exp = expectation(description: "Produces")
        Task {
            defer { exp.fulfill() }
            do {
                _ = try await sut.awaitValue()
                XCTFail("Error expected to be thrown.")
            } catch TestError.testCase {
                XCTAssert(true)
            } catch {
                XCTFail("Wrong thrown error type")
            }
        }

        await fulfillment(of: [exp], timeout: 1.0)
    }

    func test_reject_resolvesWithMostRecentError() async throws {
        let sut = makeSUT()
        await sut.reject(error: TestError.testCase)
        await sut.reject(error: TestError.testCase2)

        let exp = expectation(description: "Produces")
        Task {
            defer { exp.fulfill() }
            do {
                _ = try await sut.awaitValue()
                XCTFail()
            } catch TestError.testCase2 {
                XCTAssert(true)
            } catch {
                XCTFail("Wrong thrown error type")
            }
        }

        await fulfillment(of: [exp], timeout: 1.0)
    }

    func test_isWaiting_initiallyFalse() async {
        let sut = makeSUT()

        let isWaiting = await sut.isWaiting
        XCTAssertFalse(isWaiting)
    }

    func test_isWaiting_trueWhenWaiting() async {
        let sut = makeSUT()
        let exp = expectation(description: "Wait for task")

        Task {
            _ = try await sut.awaitValue()
        }

        Task {
            try await allowTasksToProgress()
            exp.fulfill()
        }

        await fulfillment(of: [exp])

        let isWaiting = await sut.isWaiting
        XCTAssertTrue(isWaiting)

        await sut.cancel()
    }

    func test_isWaiting_falseWhenFulfilled() async throws {
        let sut = makeSUT()
        let exp = expectation(description: "Wait for tasks")
        exp.expectedFulfillmentCount = 2

        Task {
            _ = try await sut.awaitValue()
            exp.fulfill()
        }

        Task {
            try await allowTasksToProgress()
            await sut.fulfill(42)
            try await allowTasksToProgress()
            exp.fulfill()
        }

        await fulfillment(of: [exp])

        let isWaiting = await sut.isWaiting
        XCTAssertFalse(isWaiting)
    }

    func test_isWaiting_falseWhenRejected() async throws {
        let sut = makeSUT()
        let exp = expectation(description: "Wait for tasks")
        exp.expectedFulfillmentCount = 2

        Task {
            _ = try? await sut.awaitValue()
            exp.fulfill()
        }

        Task {
            try await allowTasksToProgress()
            await sut.reject(error: anyError())
            try await allowTasksToProgress()
            exp.fulfill()
        }

        await fulfillment(of: [exp])

        let isWaiting = await sut.isWaiting
        XCTAssertFalse(isWaiting)
    }

    func test_isWaiting_falseWhenCancelled() async throws {
        let sut = makeSUT()
        let exp = expectation(description: "Wait for tasks")
        exp.expectedFulfillmentCount = 2

        Task {
            _ = try? await sut.awaitValue()
            exp.fulfill()
        }

        Task {
            try await allowTasksToProgress()
            await sut.cancel()
            try await allowTasksToProgress()
            exp.fulfill()
        }

        await fulfillment(of: [exp])

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

    private func allowTasksToProgress() async throws {
        try await Task.sleep(for: .milliseconds(200))
    }
}
