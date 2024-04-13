import Combine
import Foundation
import SwiftUI
import TestHelpers
import VaultCore
import VaultFeed
import XCTest
@testable import VaultiOS

final class CodeTimerHorizontalBarViewTests: XCTestCase {
    // MARK: - Helpers

    @MainActor
    private func makeSUT(
        currentTime: Double = 100,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (PassthroughSubject<OTPCodeTimerState, Never>, CodeTimerHorizontalBarView) {
        let clock = EpochClock(makeCurrentTime: { currentTime })
        let updater = PassthroughSubject<OTPCodeTimerState, Never>()
        let state = OTPCodeTimerPeriodState(clock: clock, statePublisher: updater.eraseToAnyPublisher())
        let view = CodeTimerHorizontalBarView(timerState: state)
        trackForMemoryLeaks(clock, file: file, line: line)
        return (updater, view)
    }

    private func rootView(of sut: some View) throws -> InspectableView<ViewType.GeometryReader> {
        try sut.inspect().geometryReader()
    }
}
