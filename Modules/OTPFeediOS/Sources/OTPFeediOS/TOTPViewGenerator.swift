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

/// This is the key: we need some kind of shared object that tracks the state for each period so it can be shaed
final class CodeTimerProgressState: ObservableObject {
    @Published var progress = CodeTimerProgress.freeze(fraction: 0)

    var cancellable: AnyCancellable?

    init(updater: some CodeTimerUpdater, clock: EpochClock) {
        cancellable = updater.timerProgressPublisher(currentTime: clock.makeCurrentTime)
            .sink { [weak self] progress in
                self?.progress = progress
            }
    }
}

// FIXME: 'startAnimating' state should use real time (not just a relative 'duration' value) so if the animation is interrupted we can restart the animation at an accurate time.
// e.g. `case startAnimating(startTime: Double, endTime: Double)`
enum CodeTimerProgress: Equatable {
    case freeze(fraction: Double)
    case startAnimating(startFraction: Double, duration: Double)

    var initialFraction: Double {
        switch self {
        case let .freeze(fraction), let .startAnimating(fraction, _):
            return fraction
        }
    }
}

extension OTPTimerState {
    func codeTimerProgress(currentTime time: Double) -> CodeTimerProgress {
        let completed = fractionCompleted(at: time)
        let remainingTime = remainingTime(at: time)
        return .startAnimating(startFraction: 1 - completed, duration: remainingTime)
    }
}

extension CodeTimerUpdater {
    /// Maps timer state updates to events that can be rendered by the progress bar.
    func timerProgressPublisher(currentTime: @escaping () -> Double) -> AnyPublisher<CodeTimerProgress, Never> {
        timerUpdatedPublisher().map { state in
            state.codeTimerProgress(currentTime: currentTime())
        }
        .removeDuplicates()
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}

@MainActor
public final class TOTPPreviewViewGenerator: TOTPViewGenerator {
    let clock: EpochClock
    let timer: LiveIntervalTimer
    let hideCodes: Bool

    private var timerCache = [UInt64: CodeTimerController<LiveIntervalTimer>]()
    private var progressStates = [UInt64: CodeTimerProgressState]()

    public init(clock: EpochClock, timer: LiveIntervalTimer, hideCodes: Bool) {
        self.clock = clock
        self.timer = timer
        self.hideCodes = hideCodes
    }

    private func getTimer(period: UInt64) -> CodeTimerController<LiveIntervalTimer> {
        if let timer = timerCache[period] {
            return timer
        } else {
            let timerController = CodeTimerController(timer: timer, period: period, clock: clock)
            timerCache[period] = timerController
            return timerController
        }
    }

    private func getCodeTimerProgressState(updater: some CodeTimerUpdater, period: UInt64) -> CodeTimerProgressState {
        if let state = progressStates[period] {
            return state
        } else {
            let state = CodeTimerProgressState(updater: updater, clock: clock)
            progressStates[period] = state
            return state
        }
    }

    public func makeTOTPView(period: UInt64, code: OTPAuthCode) -> some View {
        let timerController = getTimer(period: period)
        let totpGenerator = TOTPGenerator(generator: code.hotpGenerator(), timeInterval: period)
        let renderer = TOTPCodeRenderer(timer: timerController, totpGenerator: totpGenerator)
        let previewViewModel = CodePreviewViewModel(
            accountName: code.accountName,
            issuer: code.issuer,
            renderer: renderer
        )
        return TOTPCodePreviewView(
            previewViewModel: previewViewModel,
            timerView: makeTimerView(updater: timerController, period: period),
            hideCode: hideCodes
        )
    }

    private func makeTimerView(updater: some CodeTimerUpdater, period: UInt64) -> some View {
        CodeTimerHorizontalBarView(
            codeTimerProgressState: getCodeTimerProgressState(updater: updater, period: period)
        )
    }
}
