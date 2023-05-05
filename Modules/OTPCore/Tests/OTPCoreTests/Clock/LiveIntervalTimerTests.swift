import Foundation
import OTPCore
import XCTest

final class LiveIntervalTimerTests: XCTestCase {
    @MainActor
    func test_wait_publishesAfterWait() async throws {
        let sut = LiveIntervalTimer()

        let publisher = sut.wait(for: 0.5).collect(1).first()

        let values: [Void] = try awaitPublisher(publisher, timeout: 2.0, when: {})
        XCTAssertEqual(values.count, 1)
    }

    @MainActor
    func test_wait_doesNotPublishBeforeWait() async throws {
        let sut = LiveIntervalTimer()

        let publisher = sut.wait(for: 1).collect(1).first()

        await awaitNoPublish(publisher: publisher, timeout: 0.5, when: {})
    }
}
