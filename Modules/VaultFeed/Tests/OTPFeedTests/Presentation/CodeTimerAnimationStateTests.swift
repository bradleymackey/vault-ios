import Foundation
import VaultFeed
import XCTest

final class CodeTimerAnimationStateTests: XCTestCase {
    func test_initialFraction_freezeIsFraction() {
        let sut = CodeTimerAnimationState.freeze(fraction: 0.69)

        XCTAssertEqual(sut.initialFraction(currentTime: 0), 0.69, accuracy: .ulpOfOne)
    }

    func test_initialFraction_animateIsStartFraction() {
        let state = OTPTimerState(startTime: 0, endTime: 10)
        let sut = CodeTimerAnimationState.animate(state)

        XCTAssertEqual(sut.initialFraction(currentTime: 3), 0.70, accuracy: .ulpOfOne)
    }

    func test_countdownFromTimerState_nilCreatesFrozenAtZero() {
        let sut = CodeTimerAnimationState.countdownFrom(timerState: nil)

        XCTAssertEqual(sut, .freeze(fraction: 0))
    }

    func test_countdownFromTimerState_createsWithTimer() {
        let timer = OTPTimerState(startTime: 100, endTime: 200)
        let sut = CodeTimerAnimationState.countdownFrom(timerState: timer)

        XCTAssertEqual(sut, .animate(timer))
    }
}
