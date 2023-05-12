import Combine
import Foundation
import OTPCore
import OTPFeed
import SwiftUI
import ViewInspector
import XCTest
@testable import OTPFeediOS

@MainActor
final class CodeTimerHorizontalBarViewTests: XCTestCase {
    // MARK: - Helpers

    private func makeSUT(
        currentTime: Double = 100,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (PassthroughSubject<OTPTimerState, Never>, CodeTimerHorizontalBarView) {
        let clock = EpochClock(makeCurrentTime: { currentTime })
        let updater = PassthroughSubject<OTPTimerState, Never>()
        let state = CodeTimerPeriodState(statePublisher: updater.eraseToAnyPublisher())
        let view = CodeTimerHorizontalBarView(timerState: state, clock: clock)
        trackForMemoryLeaks(clock, file: file, line: line)
        return (updater, view)
    }

    private func rootView(of sut: some View) throws -> InspectableView<ViewType.GeometryReader> {
        try sut.inspect().geometryReader()
    }
}
