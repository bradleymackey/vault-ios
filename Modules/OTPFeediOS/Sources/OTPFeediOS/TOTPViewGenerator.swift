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
public struct LiveTOTPPreviewViewGenerator: TOTPViewGenerator {
    let clock: EpochClock
    let timer: LiveIntervalTimer

    public init(clock: EpochClock, timer: LiveIntervalTimer) {
        self.clock = clock
        self.timer = timer
    }

    public func makeTOTPView(period: UInt64, code: OTPAuthCode) -> some View {
        let timerController = CodeTimerController(timer: timer, period: period, clock: clock)
        let totpGenerator = TOTPGenerator(generator: code.hotpGenerator(), timeInterval: period)
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

@MainActor
public struct LiveTOTPItemViewDecorator<Generator: TOTPViewGenerator>: TOTPViewGenerator {
    let generator: Generator
    let onDetailTap: (OTPAuthCode) -> Void

    public init(generator: Generator, onDetailTap: @escaping (OTPAuthCode) -> Void) {
        self.generator = generator
        self.onDetailTap = onDetailTap
    }

    public func makeTOTPView(period: UInt64, code: OTPAuthCode) -> some View {
        let baseView = generator.makeTOTPView(period: period, code: code)
        return OTPFeedItemView(preview: baseView, buttonPadding: 8) {
            onDetailTap(code)
        }
    }
}
