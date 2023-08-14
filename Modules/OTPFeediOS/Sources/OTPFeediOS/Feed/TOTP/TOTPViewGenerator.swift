import Combine
import CryptoEngine
import OTPCore
import OTPFeed
import SwiftUI

@MainActor
public protocol TOTPViewGenerator {
    associatedtype CodeView: View
    func makeTOTPView(period: UInt64, code: StoredOTPCode) -> CodeView
}

/// An efficient generator of preview views for TOTP codes.
///
/// Internal caching and sharing of models and timers makes this very efficient.
@MainActor
public final class TOTPPreviewViewGenerator: ObservableObject, TOTPViewGenerator {
    let clock: EpochClock
    let timer: LiveIntervalTimer
    let isEditing: Bool

    private var periodCache = [UInt64: PeriodCachedObjects]()

    private var viewModelCache = [UUID: CodePreviewViewModel]()

    public init(clock: EpochClock, timer: LiveIntervalTimer, isEditing: Bool) {
        self.clock = clock
        self.timer = timer
        self.isEditing = isEditing
    }

    public func makeTOTPView(period: UInt64, code: StoredOTPCode) -> some View {
        let cachedObjects = makeControllersForPeriod(period: period)
        let previewViewModel = makeViewModelForCode(
            period: period,
            code: code,
            timerController: cachedObjects.timerController
        )
        return TOTPCodePreviewView(
            previewViewModel: previewViewModel,
            timerView: CodeTimerHorizontalBarView(
                timerState: cachedObjects.periodState,
                color: .blue
            ),
            hideCode: isEditing
        )
    }
}

// MARK: - Caching

extension TOTPPreviewViewGenerator {
    private struct PeriodCachedObjects {
        let timerController: CodeTimerController<LiveIntervalTimer>
        let periodState: CodeTimerPeriodState
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

    private func makeViewModelForCode(
        period: UInt64,
        code: StoredOTPCode,
        timerController: CodeTimerController<LiveIntervalTimer>
    ) -> CodePreviewViewModel {
        if let viewModel = viewModelCache[code.id] {
            return viewModel
        } else {
            let totpGenerator = TOTPGenerator(generator: code.code.hotpGenerator(), timeInterval: period)
            let renderer = TOTPCodeRenderer(timer: timerController, totpGenerator: totpGenerator)
            let viewModel = CodePreviewViewModel(
                accountName: code.code.accountName,
                issuer: code.code.issuer,
                renderer: renderer
            )
            viewModelCache[code.id] = viewModel
            return viewModel
        }
    }
}
