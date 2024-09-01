import Foundation
import FoundationExtensions
import TestHelpers
import VaultCore
import XCTest

final class IntervalTimerImplTests: XCTestCase {
    func test_waitAsync_negativeCompletesImmediately() async throws {
        let sut = IntervalTimerImpl()

        let exp = expectation(description: "Wait for fulfull")
        Task {
            try await sut.wait(for: -20)
            exp.fulfill()
        }

        await fulfillment(of: [exp], timeout: 2)
    }

    func test_waitAsync_zeroCompletesImmediately() async throws {
        let sut = IntervalTimerImpl()

        let exp = expectation(description: "Wait for fulfull")
        Task {
            try await sut.wait(for: 0)
            exp.fulfill()
        }

        await fulfillment(of: [exp], timeout: 2)
    }

    func test_waitAsync_publishesAfterWait() async throws {
        let sut = IntervalTimerImpl()

        let exp = expectation(description: "Wait for fulfull")
        Task {
            try await sut.wait(for: 0.5)
            exp.fulfill()
        }

        await fulfillment(of: [exp], timeout: 2)
    }

    func test_waitAsync_doesNotPublishBeforeWait() async throws {
        let sut = IntervalTimerImpl()

        let exp = expectation(description: "Wait no for fulfull")
        exp.isInverted = true
        Task {
            try await sut.wait(for: 10)
            exp.fulfill()
        }

        await fulfillment(of: [exp], timeout: 2)
    }

    func test_waitAsyncWithTolerance_publishesAfterWait() async throws {
        let sut = IntervalTimerImpl()

        let exp = expectation(description: "Wait for fulfull")
        Task {
            try await sut.wait(for: 0.5, tolerance: 0.5)
            exp.fulfill()
        }

        await fulfillment(of: [exp], timeout: 2)
    }

    func test_waitAsyncWithTolerance_doesNotPublishBeforeWait() async throws {
        let sut = IntervalTimerImpl()

        let exp = expectation(description: "Wait no for fulfull")
        exp.isInverted = true
        Task {
            try await sut.wait(for: 10, tolerance: 0.5)
            exp.fulfill()
        }

        await fulfillment(of: [exp], timeout: 2)
    }

    func test_schedule_publishesAfterWait() async throws {
        let sut = IntervalTimerImpl()

        let task = sut.schedule(wait: 0.5) {
            100
        }

        let value = try await task.value
        XCTAssertEqual(value, 100)
    }

    func test_schedule_publishesAfterWaitWithTolerance() async throws {
        let sut = IntervalTimerImpl()

        let task = sut.schedule(wait: 0.5, tolerance: 0.5) {
            100
        }

        let value = try await task.value
        XCTAssertEqual(value, 100)
    }

    func test_schedule_isolatesWorkToGlobalActor() async throws {
        @MainActor
        class Thing {
            var time = 100
        }
        let thing = Thing()
        let sut = IntervalTimerImpl()
        let exp = expectation(description: "Wait for execution")

        Task.detached(priority: .background) {
            XCTAssertFalse(Thread.isMainThread)
            sut.schedule(wait: 0.5) { @MainActor in
                XCTAssertTrue(Thread.isMainThread)
                thing.time = 200
                exp.fulfill()
            }
        }

        await fulfillment(of: [exp])
    }
}
