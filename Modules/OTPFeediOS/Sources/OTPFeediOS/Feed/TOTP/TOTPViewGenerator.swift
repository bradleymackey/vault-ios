import Combine
import CryptoEngine
import OTPCore
import OTPFeed
import SwiftUI

@MainActor
public protocol TOTPViewGenerator {
    associatedtype CodeView: View
    func makeTOTPView(period: UInt64, code: OTPAuthCode) -> CodeView
}

@MainActor
public final class TOTPPreviewViewGenerator: TOTPViewGenerator {
    let clock: EpochClock
    let timer: LiveIntervalTimer
    let hideCodes: Bool

    private var timerCache = [UInt64: CodeTimerController<LiveIntervalTimer>]()

    public init(clock: EpochClock, timer: LiveIntervalTimer, hideCodes: Bool) {
        self.clock = clock
        self.timer = timer
        self.hideCodes = hideCodes
    }

    private func makeTimer(period: UInt64) -> CodeTimerController<LiveIntervalTimer> {
        if let timer = timerCache[period] {
            return timer
        } else {
            let timerController = CodeTimerController(timer: timer, period: period, clock: clock)
            timerCache[period] = timerController
            return timerController
        }
    }

    public func makeTOTPView(period: UInt64, code: OTPAuthCode) -> some View {
        let timerController = makeTimer(period: period)
        let totpGenerator = TOTPGenerator(generator: code.hotpGenerator(), timeInterval: period)
        let renderer = TOTPCodeRenderer(timer: timerController, totpGenerator: totpGenerator)
        let previewViewModel = CodePreviewViewModel(
            accountName: code.accountName,
            issuer: code.issuer,
            renderer: renderer
        )
        return TOTPCodePreviewView(
            previewViewModel: previewViewModel,
            timerView: CodeTimerHorizontalBarView(
                timerState: CodeTimerPeriodState(statePublisher: timerController.timerUpdatedPublisher()),
                clock: clock
            ),
            hideCode: hideCodes
        )
    }
}
