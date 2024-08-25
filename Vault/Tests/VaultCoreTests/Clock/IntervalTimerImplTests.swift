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
}
