import Foundation
import OTPCore
import SwiftUI
import ViewInspector
import XCTest
@testable import OTPFeediOS

final class CodeTimerHorizontalBarViewTests: XCTestCase {
    func test_onAppear_recalculatesTimer() throws {
        let (timer, sut) = makeSUT()

        try sut.inspect().geometryReader().callOnAppear()

        XCTAssertEqual(timer.recalculateCallCount, 1)
    }

    func test_onChangeSceneState_recalculatesTimerWhenActive() throws {
        let (timer, sut) = makeSUT()

        let newState = ScenePhase.active
        try sut.inspect().geometryReader().callOnChange(newValue: newState)

        XCTAssertEqual(timer.recalculateCallCount, 1)
    }

    func test_onChangeSceneState_doesNotRecalculateTimerWhenNotActive() throws {
        let (timer, sut) = makeSUT()

        try sut.inspect().geometryReader().callOnChange(newValue: ScenePhase.background)
        try sut.inspect().geometryReader().callOnChange(newValue: ScenePhase.inactive)

        XCTAssertEqual(timer.recalculateCallCount, 0)
    }

    // MARK: - Helpers

    private func makeSUT(
        currentTime: Double = 100,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (MockCodeTimerUpdater, CodeTimerHorizontalBarView<MockCodeTimerUpdater>) {
        let clock = EpochClock(makeCurrentTime: { currentTime })
        let updater = MockCodeTimerUpdater()
        let view = CodeTimerHorizontalBarView(clock: clock, updater: updater)
        trackForMemoryLeaks(clock, file: file, line: line)
        trackForMemoryLeaks(updater, file: file, line: line)
        return (updater, view)
    }
}
