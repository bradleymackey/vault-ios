import Foundation
import XCTest
@testable import OTPFeediOS

final class CodeTimerAnimationStateTests: XCTestCase {
    func test_initialFraction_freezeIsFraction() {
        let sut = CodeTimerAnimationState.freeze(fraction: 0.69)

        XCTAssertEqual(sut.initialFraction, 0.69, accuracy: .ulpOfOne)
    }

    func test_initialFraction_animateIsStartFraction() {
        let sut = CodeTimerAnimationState.animate(startFraction: 0.68, duration: 100)

        XCTAssertEqual(sut.initialFraction, 0.68, accuracy: .ulpOfOne)
    }

    func test_initFromTimerState_nilCreatesFrozenAtZero() {
        let sut = CodeTimerAnimationState(timerState: nil)

        XCTAssertEqual(sut, .freeze(fraction: 0))
    }
}
