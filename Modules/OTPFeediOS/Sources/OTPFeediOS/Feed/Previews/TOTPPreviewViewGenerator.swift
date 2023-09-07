import Combine
import CoreModels
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

    private var periodCache = Cache<UInt64, PeriodCachedObjects>()
    private var viewModelCache = Cache<UUID, CodePreviewViewModel>()

    public init(clock: EpochClock, timer: any IntervalTimer) {
        self.clock = clock
        self.timer = timer
    }

    public func makeOTPView(id: UUID, code: Code, behaviour: OTPViewBehaviour?) -> some View {
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
            behaviour: behaviour
        )
    }

    /// Get the current visible code for a given generated code.
    public func currentCode(id: UUID) -> String? {
        guard let viewModel = viewModelCache[id] else { return nil }
        return viewModel.code.visibleCode
    }
}

// MARK: - Caching

extension TOTPPreviewViewGenerator: CodeDetailCache {
    public func invalidateCache(id: UUID) {
        viewModelCache.remove(key: id)
        // don't invalidate period caches, as they are independant of the code detail
    }

    private struct PeriodCachedObjects {
        let timerController: CodeTimerController
        let periodState: CodeTimerPeriodState
    }

    private func makeControllersForPeriod(period: UInt64) -> PeriodCachedObjects {
        periodCache.getOrCreateValue(for: period) {
            let timerController = CodeTimerController(timer: timer, period: period, clock: clock)
            let periodState = CodeTimerPeriodState(
                clock: clock,
                statePublisher: timerController.timerUpdatedPublisher()
            )
            return PeriodCachedObjects(timerController: timerController, periodState: periodState)
        }
    }

    private func makeViewModelForCode(
        id: UUID,
        code: TOTPAuthCode,
        timerController: CodeTimerController
    ) -> CodePreviewViewModel {
        viewModelCache.getOrCreateValue(for: id) {
            let totpGenerator = TOTPGenerator(generator: code.data.hotpGenerator(), timeInterval: code.period)
            let renderer = TOTPCodeRenderer(timer: timerController, totpGenerator: totpGenerator)
            return CodePreviewViewModel(
                accountName: code.data.accountName,
                issuer: code.data.issuer,
                renderer: renderer
            )
        }
    }
}
