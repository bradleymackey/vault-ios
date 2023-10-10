import Foundation
import FoundationExtensions
import XCTest

final class PendingValueTests: XCTestCase {
    enum TestError: Error {
        case testCase
        case testCase2
    }

    func test_fulfill_unsuspendsAwait() async throws {
        let producer = PendingValue<Int>()
        let exp = expectation(description: "waiting for value")
        Task {
            let result = try await producer.awaitValue()
            XCTAssertEqual(result, 42)
            exp.fulfill()
        }
        Task {
            try await Task.sleep(for: .milliseconds(100))
            producer.fulfill(42)
        }

        await fulfillment(of: [exp], timeout: 1.0)
    }

    func test_reject_unsuspendsAwait() async throws {
        let producer = PendingValue<Int>()
        let exp = expectation(description: "waiting for value")
        Task {
            defer { exp.fulfill() }
            do {
                _ = try await producer.awaitValue()
                XCTFail()
            } catch {
                XCTAssert(error is TestError)
            }
        }
        Task {
            try await Task.sleep(for: .milliseconds(100))
            producer.reject(error: TestError.testCase)
        }

        await fulfillment(of: [exp], timeout: 1.0)
    }

    func test_fulfill_beforeAwaitingReturnsInitialValue() async throws {
        let producer = PendingValue<Int>()
        producer.fulfill(42)
        let exp = expectation(description: "Produces")
        Task {
            defer { exp.fulfill() }
            let value = try await producer.awaitValue()
            XCTAssertEqual(value, 42)
        }

        await fulfillment(of: [exp], timeout: 1.0)
    }

    func test_fulfill_remembersMostRecentValueOnly() async throws {
        let producer = PendingValue<Int>()
        producer.fulfill(42)
        producer.fulfill(43)
        producer.fulfill(44)

        let exp = expectation(description: "Produces")
        Task {
            defer { exp.fulfill() }
            let value = try await producer.awaitValue()
            // The most recent value.
            XCTAssertEqual(value, 44)
        }

        await fulfillment(of: [exp], timeout: 1.0)
    }

    func test_reject_beforeAwaitResolvesWithInitialError() async throws {
        let producer = PendingValue<Int>()
        producer.reject(error: TestError.testCase)

        let exp = expectation(description: "Produces")
        Task {
            defer { exp.fulfill() }
            do {
                _ = try await producer.awaitValue()
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
        let producer = PendingValue<Int>()
        producer.reject(error: TestError.testCase)
        producer.reject(error: TestError.testCase2)

        let exp = expectation(description: "Produces")
        Task {
            defer { exp.fulfill() }
            do {
                _ = try await producer.awaitValue()
                XCTFail()
            } catch TestError.testCase2 {
                XCTAssert(true)
            } catch {
                XCTFail("Wrong thrown error type")
            }
        }

        await fulfillment(of: [exp], timeout: 1.0)
    }
}
