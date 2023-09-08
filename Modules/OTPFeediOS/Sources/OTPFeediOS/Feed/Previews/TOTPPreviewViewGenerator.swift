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
public final class TOTPPreviewViewGenerator<Factory: TOTPPreviewViewFactory>: ObservableObject, OTPViewGenerator {
    public typealias Code = TOTPAuthCode

    let viewFactory: Factory
    let clock: EpochClock
    let timer: any IntervalTimer

    private var timerControllerCache = Cache<UInt64, CodeTimerController>()
    private var timerPeriodStateCache = Cache<UInt64, CodeTimerPeriodState>()
    private var viewModelCache = Cache<UUID, CodePreviewViewModel>()

    public init(viewFactory: Factory, clock: EpochClock, timer: any IntervalTimer) {
        self.viewFactory = viewFactory
        self.clock = clock
        self.timer = timer
    }

    public func makeOTPView(id: UUID, code: Code, behaviour: OTPViewBehaviour?) -> some View {
        viewFactory.makeTOTPView(
            viewModel: makeViewModelForCode(id: id, code: code),
            periodState: makeTimerPeriodState(period: code.period),
            behaviour: behaviour
        )
    }

    /// Get the current visible code for a given generated code.
    public func currentCode(id: UUID) -> String? {
        guard let viewModel = viewModelCache[id] else { return nil }
        return viewModel.code.visibleCode
    }

    public func recalculateAllTimers() {
        for timerController in timerControllerCache.values {
            timerController.recalculate()
        }
    }
}

// MARK: - Caching

extension TOTPPreviewViewGenerator: CodeDetailCache {
    public func invalidateCache(id: UUID) {
        viewModelCache.remove(key: id)
        // don't invalidate period caches, as they are independant of the code detail
    }

    private func makeTimerController(period: UInt64) -> CodeTimerController {
        timerControllerCache.getOrCreateValue(for: period) {
            CodeTimerController(timer: timer, period: period, clock: clock)
        }
    }

    private func makeTimerPeriodState(period: UInt64) -> CodeTimerPeriodState {
        timerPeriodStateCache.getOrCreateValue(for: period) {
            let timerController = makeTimerController(period: period)
            return CodeTimerPeriodState(clock: clock, statePublisher: timerController.timerUpdatedPublisher())
        }
    }

    private func makeViewModelForCode(
        id: UUID,
        code: TOTPAuthCode
    ) -> CodePreviewViewModel {
        viewModelCache.getOrCreateValue(for: id) {
            let totpGenerator = TOTPGenerator(generator: code.data.hotpGenerator(), timeInterval: code.period)
            let renderer = TOTPCodeRenderer(
                timer: makeTimerController(period: code.period),
                totpGenerator: totpGenerator
            )
            return CodePreviewViewModel(
                accountName: code.data.accountName,
                issuer: code.data.issuer,
                renderer: renderer
            )
        }
    }
}
