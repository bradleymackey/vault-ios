import Foundation
import OTPCore
import XCTest

@MainActor
final class LiveIntervalTimerTests: XCTestCase {
    func test_wait_publishesAfterWait() async throws {
        let sut = LiveIntervalTimer()

        let publisher = sut.wait(for: 0.5).collect(1).first()

        let values: [Void] = try awaitPublisher(publisher, timeout: 2.0, when: {})
        XCTAssertEqual(values.count, 1)
    }

    func test_wait_doesNotPublishBeforeWait() async throws {
        let sut = LiveIntervalTimer()
        let publisher = sut.wait(for: 5).collect(1).first()

        // We're waiting for 5 seconds, but check after 1 second for tolerance.
        await awaitNoPublish(publisher: publisher, timeout: 1, when: {})
    }
}
