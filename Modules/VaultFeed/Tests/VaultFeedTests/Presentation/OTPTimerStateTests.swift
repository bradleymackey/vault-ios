import Foundation
import VaultFeed
import XCTest

final class OTPTimerStateTests: XCTestCase {
    func test_totalTime_isDurationOfTimeRangePositive() {
        let sut = OTPTimerState(startTime: 150, endTime: 250)
        let totalTime = sut.totalTime
        XCTAssertEqual(totalTime, 100, accuracy: .ulpOfOne)
    }

    func test_totalTime_isDurationOfTimeRangeNegative() {
        let sut = OTPTimerState(startTime: 250, endTime: 150)
        let totalTime = sut.totalTime
        XCTAssertEqual(totalTime, -100, accuracy: .ulpOfOne)
    }

    func test_remainingTime_isTimeRemaining() {
        let sut = OTPTimerState(startTime: 350, endTime: 450)
        let timeRemaining = sut.remainingTime(at: 399)
        XCTAssertEqual(timeRemaining, 51, accuracy: .ulpOfOne)
    }

    func test_remainingTime_isTimeRemainingClampsToZero() {
        let sut = OTPTimerState(startTime: 350, endTime: 450)
        let timeRemaining = sut.remainingTime(at: 461)
        XCTAssertEqual(timeRemaining, 0, accuracy: .ulpOfOne)
    }

    func test_fractionCompleted_isFractionOfRangeCompleted() {
        let sut = OTPTimerState(startTime: 350, endTime: 450)
        let fractionCompleted = sut.fractionCompleted(at: 360)
        XCTAssertEqual(fractionCompleted, 0.1, accuracy: .ulpOfOne)
    }

    func test_fractionCompleted_isFractionOfRangeCompletedZero() {
        let sut = OTPTimerState(startTime: 350, endTime: 450)
        let fractionCompleted = sut.fractionCompleted(at: 350)
        XCTAssertEqual(fractionCompleted, 0, accuracy: .ulpOfOne)
    }

    func test_fractionCompleted_isFractionOfRangeCompletedCapsToZero() {
        let sut = OTPTimerState(startTime: 350, endTime: 450)
        let fractionCompleted = sut.fractionCompleted(at: 340)
        XCTAssertEqual(fractionCompleted, 0, accuracy: .ulpOfOne)
    }

    func test_fractionCompleted_isFractionOfRangeCompletedOne() {
        let sut = OTPTimerState(startTime: 350, endTime: 450)
        let fractionCompleted = sut.fractionCompleted(at: 450)
        XCTAssertEqual(fractionCompleted, 1, accuracy: .ulpOfOne)
    }

    func test_fractionCompleted_isFractionOfRangeCompletedCapsToOne() {
        let sut = OTPTimerState(startTime: 350, endTime: 450)
        let fractionCompleted = sut.fractionCompleted(at: 460)
        XCTAssertEqual(fractionCompleted, 1, accuracy: .ulpOfOne)
    }
}
