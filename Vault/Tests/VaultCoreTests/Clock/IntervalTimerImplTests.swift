import Combine
import Foundation
import FoundationExtensions
import TestHelpers
import VaultCore
import XCTest

final class IntervalTimerImplTests: XCTestCase {
    @MainActor
    func test_wait_publishesOnMain() async throws {
        let exp = expectation(description: "Wait")
        let handle = Atomic<AnyCancellable?>(initialValue: nil)

        DispatchQueue.global(qos: .background).async {
            let sut = IntervalTimerImpl()
            handle.modify {
                $0 = sut.wait(for: 0.1).sink {
                    XCTAssertTrue(Thread.isMainThread)
                    exp.fulfill()
                }
            }
        }

        await fulfillment(of: [exp], timeout: 2.0)

        handle.modify { $0?.cancel() }
    }

    @MainActor
    func test_wait_negativeCompletesImmediately() async throws {
        let sut = IntervalTimerImpl()

        let publisher = sut.wait(for: -20).collect(1).first()

        let values: [Void] = try await awaitPublisher(publisher, timeout: 2.0, when: {})
        XCTAssertEqual(values.count, 1)
    }

    @MainActor
    func test_wait_zeroCompletesImmediately() async throws {
        let sut = IntervalTimerImpl()

        let publisher = sut.wait(for: 0.0).collect(1).first()

        let values: [Void] = try await awaitPublisher(publisher, timeout: 2.0, when: {})
        XCTAssertEqual(values.count, 1)
    }

    @MainActor
    func test_wait_publishesAfterWait() async throws {
        let sut = IntervalTimerImpl()

        let publisher = sut.wait(for: 0.5).collect(1).first()

        let values: [Void] = try await awaitPublisher(publisher, timeout: 2.0, when: {})
        XCTAssertEqual(values.count, 1)
    }

    @MainActor
    func test_wait_doesNotPublishBeforeWait() async throws {
        let sut = IntervalTimerImpl()
        let publisher = sut.wait(for: 5).collect(1).first()

        // We're waiting for 5 seconds, but check after 1 second for tolerance.
        await awaitNoPublish(publisher: publisher, timeout: 1, when: {})
    }

    @MainActor
    func test_waitWithTolerance_publishesAfterWait() async throws {
        let sut = IntervalTimerImpl()

        let publisher = sut.wait(for: 0.5, tolerance: 0.1).collect(1).first()

        let values: [Void] = try await awaitPublisher(publisher, timeout: 2.0, when: {})
        XCTAssertEqual(values.count, 1)
    }

    @MainActor
    func test_waitWithTolerance_doesNotPublishBeforeWait() async throws {
        let sut = IntervalTimerImpl()
        let publisher = sut.wait(for: 5, tolerance: 0.1).collect(1).first()

        // We're waiting for 5 seconds, but check after 1 second for tolerance.
        await awaitNoPublish(publisher: publisher, timeout: 1, when: {})
    }

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
