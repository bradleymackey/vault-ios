import Foundation
import OTPCore
import OTPFeed
import OTPFeediOS
import SwiftUI
import TestHelpers
import XCTest

@MainActor
final class TOTPPreviewViewGeneratorTests: XCTestCase {
    func test_init_hasNoSideEffects() {
        let factory = MockTOTPViewFactory()
        let timer = MockIntervalTimer()
        _ = makeSUT(factory: factory, timer: timer)

        XCTAssertEqual(factory.makeTOTPViewExecutedCount, 0)
        XCTAssertEqual(timer.recordedWaitedIntervals, [])
    }
}

extension TOTPPreviewViewGeneratorTests {
    private typealias SUT = TOTPPreviewViewGenerator<MockTOTPViewFactory>
    private func makeSUT(
        factory: MockTOTPViewFactory = MockTOTPViewFactory(),
        clock: EpochClock = EpochClock { 100 },
        timer: MockIntervalTimer = MockIntervalTimer()
    ) -> SUT {
        SUT(viewFactory: factory, clock: clock, timer: timer)
    }

    private final class MockTOTPViewFactory: TOTPPreviewViewFactory {
        var makeTOTPViewExecutedCount = 0
        var makeTOTPViewExecuted: (CodePreviewViewModel, CodeTimerPeriodState, OTPViewBehaviour?) -> Void = { _, _, _ in
        }

        func makeTOTPView(
            viewModel: CodePreviewViewModel,
            periodState: CodeTimerPeriodState,
            behaviour: OTPViewBehaviour?
        ) -> some View {
            makeTOTPViewExecutedCount += 1
            makeTOTPViewExecuted(viewModel, periodState, behaviour)
            return Text("Hello, TOTP!")
        }
    }
}
