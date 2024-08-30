import Foundation
import FoundationExtensions
import XCTest

final class TaskContinuationTests: XCTestCase {
    func test_runsTaskToCompletion() async throws {
        let exp = expectation(description: "Wait for task")
        try await Task.continuation {
            exp.fulfill()
        }

        await fulfillment(of: [exp])
    }

    func test_cancellationCancelsTask() async throws {
        let exp1 = expectation(description: "Wait for task start")
        let exp2 = expectation(description: "Wait for continuation to finish")
        let exp3 = expectation(description: "Wait for continuation to throw")
        exp3.isInverted = true
        let outer = Task {
            exp1.fulfill()
            let result = try await Task.continuation {
                sleep(1) // heavy work
                exp2.fulfill() // task still finishes, even if cancelled
                return 100
            }
            exp3.fulfill() // continutation should throw before here
            return result
        }
        await fulfillment(of: [exp1])

        outer.cancel()

        await fulfillment(of: [exp2, exp3], timeout: 2, enforceOrder: true)

        let error = await withCatchingAsyncError {
            try await outer.result.get()
        }
        XCTAssertTrue(error is CancellationError)
    }
}
