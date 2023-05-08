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
        let delays: [(delay: Double, repetitions: Int)] = [
            (0.01, 30),
            (0.02, 10),
            (0.1, 5),
            (0.2, 3),
            (0.5, 2),
            (1, 1),
            (2, 1),
        ]

        for testCase in delays {
            for _ in 0 ..< testCase.repetitions {
                let publisher = sut.wait(for: testCase.delay).collect(1).first()

                // We should publish very slightly after the delay, so nothing should be seen here.
                await awaitNoPublish(publisher: publisher, timeout: testCase.delay - .ulpOfOne, when: {})
            }
        }
    }
}
