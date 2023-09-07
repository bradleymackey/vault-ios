import Foundation
import OTPFeediOS
import XCTest

@MainActor
final class HOTPPreviewViewGeneratorTests: XCTestCase {
    func test_init_hasNoSideEffects() {
        let (_, timer) = makeSUT()

        XCTAssertEqual(timer.recordedWaitedIntervals, [])
    }
}

extension HOTPPreviewViewGeneratorTests {
    private func makeSUT() -> (HOTPPreviewViewGenerator, MockIntervalTimer) {
        let timer = MockIntervalTimer()
        let sut = HOTPPreviewViewGenerator(timer: timer)
        return (sut, timer)
    }
}
