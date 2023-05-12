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

    private struct PeriodCachedObjects {
        let timerController: CodeTimerController<LiveIntervalTimer>
        let periodState: CodeTimerPeriodState
    }

    private var periodCache = [UInt64: PeriodCachedObjects]()

    public init(clock: EpochClock, timer: LiveIntervalTimer, hideCodes: Bool) {
        self.clock = clock
        self.timer = timer
        self.hideCodes = hideCodes
    }

    private func makeControllersForPeriod(period: UInt64) -> PeriodCachedObjects {
        if let controllers = periodCache[period] {
            return controllers
        } else {
            let timerController = CodeTimerController(timer: timer, period: period, clock: clock)
            let periodState = CodeTimerPeriodState(
                clock: clock,
                statePublisher: timerController.timerUpdatedPublisher()
            )
            let cacheEntry = PeriodCachedObjects(timerController: timerController, periodState: periodState)
            periodCache[period] = cacheEntry
            return cacheEntry
        }
    }

    public func makeTOTPView(period: UInt64, code: OTPAuthCode) -> some View {
        let cachedObjects = makeControllersForPeriod(period: period)
        let totpGenerator = TOTPGenerator(generator: code.hotpGenerator(), timeInterval: period)
        let renderer = TOTPCodeRenderer(timer: cachedObjects.timerController, totpGenerator: totpGenerator)
        let previewViewModel = CodePreviewViewModel(
            accountName: code.accountName,
            issuer: code.issuer,
            renderer: renderer
        )
        return TOTPCodePreviewView(
            previewViewModel: previewViewModel,
            timerView: CodeTimerHorizontalBarView(
                timerState: cachedObjects.periodState
            ),
            hideCode: hideCodes
        )
    }
}
