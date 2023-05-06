import CryptoEngine
import OTPCore
import OTPFeed
import SwiftUI

public protocol TOTPViewGenerator {
    associatedtype CodeView: View
    func makeTOTPView(period: UInt32, code: OTPAuthCode) -> CodeView
}

public struct LiveTOTPViewGenerator: TOTPViewGenerator {
    let clock: EpochClock
    let timer: LiveIntervalTimer

    public init(clock: EpochClock, timer: LiveIntervalTimer) {
        self.clock = clock
        self.timer = timer
    }

    public func makeTOTPView(period: UInt32, code: OTPAuthCode) -> some View {
        let timerController = CodeTimerController(timer: timer, period: Double(period), clock: clock)
        let totpGenerator = TOTPGenerator(generator: code.hotpGenerator(), timeInterval: UInt64(period))
        let renderer = TOTPCodeRenderer(timer: timerController, totpGenerator: totpGenerator)
        let previewViewModel = CodePreviewViewModel(renderer: renderer)
        let timerViewModel = CodeTimerViewModel(updater: timerController, clock: clock)
        return TOTPCodePreviewView(
            accountName: code.accountName,
            issuer: code.issuer,
            textView: .init(viewModel: previewViewModel, codeSpacing: 10.0),
            timerView: .init(viewModel: timerViewModel),
            previewViewModel: previewViewModel
        )
    }
}
