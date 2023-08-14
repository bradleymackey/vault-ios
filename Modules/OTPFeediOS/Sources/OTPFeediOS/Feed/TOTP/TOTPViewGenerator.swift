import Combine
import CryptoEngine
import OTPCore
import OTPFeed
import SwiftUI

/// An efficient generator of preview views for TOTP codes.
///
/// Internal caching and sharing of models and timers makes this very efficient.
@MainActor
public final class TOTPPreviewViewGenerator: ObservableObject, OTPViewGenerator {
    public typealias Code = TOTPAuthCode

    let clock: EpochClock
    let timer: any IntervalTimer
    let isEditing: Bool

    private var periodCache = [UInt64: PeriodCachedObjects]()

    private var viewModelCache = [UUID: CodePreviewViewModel]()

    public init(clock: EpochClock, timer: any IntervalTimer, isEditing: Bool) {
        self.clock = clock
        self.timer = timer
        self.isEditing = isEditing
    }

    public func makeOTPView(id: UUID, code: Code) -> some View {
        let cachedObjects = makeControllersForPeriod(period: code.period)
        let previewViewModel = makeViewModelForCode(
            id: id,
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
        let timerController: CodeTimerController
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
        id: UUID,
        code: TOTPAuthCode,
        timerController: CodeTimerController
    ) -> CodePreviewViewModel {
        if let viewModel = viewModelCache[id] {
            return viewModel
        } else {
            let totpGenerator = TOTPGenerator(generator: code.hotpGenerator(), timeInterval: code.period)
            let renderer = TOTPCodeRenderer(timer: timerController, totpGenerator: totpGenerator)
            let viewModel = CodePreviewViewModel(
                accountName: code.accountName,
                issuer: code.issuer,
                renderer: renderer
            )
            viewModelCache[id] = viewModel
            return viewModel
        }
    }
}
