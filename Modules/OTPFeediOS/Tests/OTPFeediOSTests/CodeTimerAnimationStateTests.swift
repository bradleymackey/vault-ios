import Foundation
import OTPFeed
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

    func test_countdownFromTimerState_nilCreatesFrozenAtZero() {
        let sut = CodeTimerAnimationState.countdownFrom(timerState: nil, currentTime: Date.now.timeIntervalSince1970)

        XCTAssertEqual(sut, .freeze(fraction: 0))
    }

    func test_countdownFromTimerState_completedIsFinished() {
        let timer = OTPTimerState(startTime: 100, endTime: 200)
        let sut = CodeTimerAnimationState.countdownFrom(timerState: timer, currentTime: 200)

        XCTAssertEqual(sut, .animate(startFraction: 0, duration: 0))
    }

    func test_countdownFromTimerState_afterCompletedIsFinished() {
        let timer = OTPTimerState(startTime: 100, endTime: 200)
        let sut = CodeTimerAnimationState.countdownFrom(timerState: timer, currentTime: 210)

        XCTAssertEqual(sut, .animate(startFraction: 0, duration: 0))
    }

    func test_countdownFromTimerState_startRunsForDuration() {
        let timer = OTPTimerState(startTime: 100, endTime: 200)
        let sut = CodeTimerAnimationState.countdownFrom(timerState: timer, currentTime: 100)

        XCTAssertEqual(sut, .animate(startFraction: 1.0, duration: 100))
    }

    func test_countdownFromTimerState_beforeTimeRunsForAdditionalTime() {
        let timer = OTPTimerState(startTime: 100, endTime: 200)
        let sut = CodeTimerAnimationState.countdownFrom(timerState: timer, currentTime: 90)

        XCTAssertEqual(sut, .animate(startFraction: 1.0, duration: 110))
    }
}
