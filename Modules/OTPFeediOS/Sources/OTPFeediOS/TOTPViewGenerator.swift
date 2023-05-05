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

    init(clock: EpochClock, timer: LiveIntervalTimer) {
        self.clock = clock
        self.timer = timer
    }

    public func makeTOTPView(period: UInt32, code: OTPAuthCode) -> some View {
        let hotpGenerator = code.hotpGenerator()
        let totpGenerator = TOTPGenerator(generator: hotpGenerator, timeInterval: UInt64(period))
        let timer = CodeTimerController(timer: timer, period: Double(period), clock: clock)
        let renderer = TOTPCodeRenderer(timer: timer, totpGenerator: totpGenerator)
        let previewViewModel = CodePreviewViewModel(renderer: renderer)
        let timerViewModel = CodeTimerViewModel(updater: timer, clock: clock)
        return TOTPCodePreviewView(
            accountName: code.accountName,
            issuer: code.issuer,
            textView: .init(viewModel: previewViewModel, codeSpacing: 10.0),
            timerView: .init(viewModel: timerViewModel),
            previewViewModel: previewViewModel
        )
    }
}
