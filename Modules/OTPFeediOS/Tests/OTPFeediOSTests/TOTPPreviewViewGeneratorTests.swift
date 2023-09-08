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

    func test_makeOTPView_generatesViews() throws {
        let sut = makeSUT()

        let view = sut.makeOTPView(id: UUID(), code: anyTOTPCode(), behaviour: .normal)

        let foundText = try view.inspect().text().string()
        XCTAssertEqual(foundText, "Hello, TOTP!")
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

    private func anyTOTPCode() -> TOTPAuthCode {
        let codeData = OTPAuthCodeData(secret: .empty(), accountName: "Test")
        return .init(data: codeData)
    }

    private final class MockTOTPViewFactory: TOTPPreviewViewFactory {
        var makeTOTPViewExecutedCount = 0
        var makeTOTPViewExecuted: (CodePreviewViewModel, CodeTimerPeriodState, OTPViewBehaviour) -> Void = { _, _, _ in
        }

        func makeTOTPView(
            viewModel: CodePreviewViewModel,
            periodState: CodeTimerPeriodState,
            behaviour: OTPViewBehaviour
        ) -> some View {
            makeTOTPViewExecutedCount += 1
            makeTOTPViewExecuted(viewModel, periodState, behaviour)
            return Text("Hello, TOTP!")
        }
    }
}
