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
public struct TOTPPreviewViewGenerator: TOTPViewGenerator {
    let clock: EpochClock
    let timer: LiveIntervalTimer
    let hideCodes: Bool

    public init(clock: EpochClock, timer: LiveIntervalTimer, hideCodes: Bool) {
        self.clock = clock
        self.timer = timer
        self.hideCodes = hideCodes
    }

    public func makeTOTPView(period: UInt64, code: OTPAuthCode) -> some View {
        let timerController = CodeTimerController(timer: timer, period: period, clock: clock)
        let totpGenerator = TOTPGenerator(generator: code.hotpGenerator(), timeInterval: period)
        let renderer = TOTPCodeRenderer(timer: timerController, totpGenerator: totpGenerator)
        let previewViewModel = CodePreviewViewModel(
            accountName: code.accountName,
            issuer: code.issuer,
            renderer: renderer
        )
        let timerViewModel = CodeTimerViewModel(updater: timerController, clock: clock)
        return TOTPCodePreviewView(
            timerView: .init(viewModel: timerViewModel),
            previewViewModel: previewViewModel,
            hideCode: hideCodes
        )
    }
}
