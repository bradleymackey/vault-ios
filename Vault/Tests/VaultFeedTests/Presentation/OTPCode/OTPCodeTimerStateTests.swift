import Foundation
import VaultFeed
import XCTest

final class OTPCodeTimerStateTests: XCTestCase {
    func test_init_startTimeAndEndTimeIsValues() {
        let sut = OTPCodeTimerState(startTime: 123, endTime: 456)

        XCTAssertEqual(sut.startTime, 123)
        XCTAssertEqual(sut.endTime, 456)
    }

    func test_init_currentTimePeriod_firstRange() {
        let sut = OTPCodeTimerState(currentTime: 50, period: 30)

        XCTAssertEqual(sut.startTime, 30)
        XCTAssertEqual(sut.endTime, 60)
    }

    func test_init_currentTimePeriod_subsequentRange() {
        let sut = OTPCodeTimerState(currentTime: 91.3, period: 30)

        XCTAssertEqual(sut.startTime, 90)
        XCTAssertEqual(sut.endTime, 120)
    }

    func test_totalTime_isDurationOfTimeRangePositive() {
        let sut = OTPCodeTimerState(startTime: 150, endTime: 250)
        let totalTime = sut.totalTime
        XCTAssertEqual(totalTime, 100, accuracy: .ulpOfOne)
    }

    func test_totalTime_isDurationOfTimeRangeNegative() {
        let sut = OTPCodeTimerState(startTime: 250, endTime: 150)
        let totalTime = sut.totalTime
        XCTAssertEqual(totalTime, -100, accuracy: .ulpOfOne)
    }

    func test_remainingTime_isTimeRemaining() {
        let sut = OTPCodeTimerState(startTime: 350, endTime: 450)
        let timeRemaining = sut.remainingTime(at: 399)
        XCTAssertEqual(timeRemaining, 51, accuracy: .ulpOfOne)
    }

    func test_remainingTime_isTimeRemainingClampsToZero() {
        let sut = OTPCodeTimerState(startTime: 350, endTime: 450)
        let timeRemaining = sut.remainingTime(at: 461)
        XCTAssertEqual(timeRemaining, 0, accuracy: .ulpOfOne)
    }

    func test_fractionCompleted_emptyTimeRangeIsCompleted() {
        let sut = OTPCodeTimerState(startTime: 100, endTime: 100)

        XCTAssertEqual(sut.fractionCompleted(at: 100), 1)
    }

    func test_fractionCompleted_isFractionOfRangeCompleted() {
        let sut = OTPCodeTimerState(startTime: 350, endTime: 450)
        let fractionCompleted = sut.fractionCompleted(at: 360)
        XCTAssertEqual(fractionCompleted, 0.1, accuracy: .ulpOfOne)
    }

    func test_fractionCompleted_isFractionOfRangeCompletedZero() {
        let sut = OTPCodeTimerState(startTime: 350, endTime: 450)
        let fractionCompleted = sut.fractionCompleted(at: 350)
        XCTAssertEqual(fractionCompleted, 0, accuracy: .ulpOfOne)
    }

    func test_fractionCompleted_isFractionOfRangeCompletedCapsToZero() {
        let sut = OTPCodeTimerState(startTime: 350, endTime: 450)
        let fractionCompleted = sut.fractionCompleted(at: 340)
        XCTAssertEqual(fractionCompleted, 0, accuracy: .ulpOfOne)
    }

    func test_fractionCompleted_isFractionOfRangeCompletedOne() {
        let sut = OTPCodeTimerState(startTime: 350, endTime: 450)
        let fractionCompleted = sut.fractionCompleted(at: 450)
        XCTAssertEqual(fractionCompleted, 1, accuracy: .ulpOfOne)
    }

    func test_fractionCompleted_isFractionOfRangeCompletedCapsToOne() {
        let sut = OTPCodeTimerState(startTime: 350, endTime: 450)
        let fractionCompleted = sut.fractionCompleted(at: 460)
        XCTAssertEqual(fractionCompleted, 1, accuracy: .ulpOfOne)
    }
}
