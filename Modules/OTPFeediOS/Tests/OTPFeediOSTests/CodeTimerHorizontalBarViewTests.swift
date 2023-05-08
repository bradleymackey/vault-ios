import Foundation
import OTPCore
import SwiftUI
import ViewInspector
import XCTest
@testable import OTPFeediOS

final class CodeTimerHorizontalBarViewTests: XCTestCase {
    func test_onAppear_recalculatesTimer() throws {
        let (timer, sut) = makeSUT()

        try rootView(of: sut).callOnAppear()

        XCTAssertEqual(timer.recalculateCallCount, 1)
    }

    func test_onChangeSceneState_recalculatesTimerWhenActive() throws {
        let (timer, sut) = makeSUT()

        try rootView(of: sut).callOnChange(newValue: ScenePhase.active)

        XCTAssertEqual(timer.recalculateCallCount, 1)
    }

    func test_onChangeSceneState_doesNotRecalculateTimerWhenNotActive() throws {
        let (timer, sut) = makeSUT()

        try rootView(of: sut).callOnChange(newValue: ScenePhase.background)
        try rootView(of: sut).callOnChange(newValue: ScenePhase.inactive)

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

    private func rootView(of sut: some View) throws -> InspectableView<ViewType.GeometryReader> {
        try sut.inspect().geometryReader()
    }
}
