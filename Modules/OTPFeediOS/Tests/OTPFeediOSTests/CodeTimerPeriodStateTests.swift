import Foundation
import XCTest
@testable import OTPFeediOS

@MainActor
final class CodeTimerPeriodStateTests: XCTestCase {
    func test_init_initialStateIsNil() {
        let sut = makeSUT()

        XCTAssertNil(sut.state)
    }

    // MARK: - Helpers

    private func makeSUT() -> CodeTimerPeriodState {
        CodeTimerPeriodState()
    }
}
