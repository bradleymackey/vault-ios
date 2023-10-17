import Combine
import CryptoEngine
import FoundationExtensions
import SwiftUI
import VaultCore
import VaultFeed

/// An efficient generator of preview views for TOTP codes.
///
/// Internal caching and sharing of models and timers makes this very efficient.
@MainActor
public final class TOTPPreviewViewGenerator<Factory: TOTPPreviewViewFactory>: VaultItemPreviewViewGenerator {
    public typealias PreviewItem = TOTPAuthCode

    let viewFactory: Factory
    let updaterFactory: any OTPCodeTimerUpdaterFactory
    let clock: EpochClock
    let timer: any IntervalTimer

    private var timerUpdaterCache = Cache<UInt64, any OTPCodeTimerUpdater>()
    private var timerPeriodStateCache = Cache<UInt64, OTPCodeTimerPeriodState>()
    private var viewModelCache = Cache<UUID, OTPCodePreviewViewModel>()

    public init(
        viewFactory: Factory,
        updaterFactory: any OTPCodeTimerUpdaterFactory,
        clock: EpochClock,
        timer: any IntervalTimer
    ) {
        self.viewFactory = viewFactory
        self.updaterFactory = updaterFactory
        self.clock = clock
        self.timer = timer
    }

    public func makeVaultPreviewView(
        item: PreviewItem,
        metadata: StoredVaultItem.Metadata,
        behaviour: VaultItemViewBehaviour
    ) -> some View {
        viewFactory.makeTOTPView(
            viewModel: makeViewModelForCode(id: metadata.id, code: item),
            periodState: makeTimerPeriodState(period: item.period),
            updater: makeTimerController(period: item.period),
            behaviour: behaviour
        )
    }

    public func scenePhaseDidChange(to scene: ScenePhase) {
        if scene == .active {
            recalculateAllTimers()
        }
    }

    public func didAppear() {
        recalculateAllTimers()
    }
}

public extension TOTPPreviewViewGenerator {
    func recalculateAllTimers() {
        for timerUpdater in timerUpdaterCache.values {
            timerUpdater.recalculate()
        }
    }
}

extension TOTPPreviewViewGenerator: VaultItemCopyTextProvider {
    public func currentCopyableText(id: UUID) -> String? {
        guard let viewModel = viewModelCache[id] else { return nil }
        return viewModel.code.visibleCode
    }
}

// MARK: - Caching

extension TOTPPreviewViewGenerator: VaultItemCache {
    public func invalidateVaultItemDetailCache(forVaultItemWithID id: UUID) {
        viewModelCache.remove(key: id)
        // don't invalidate period caches, as they are independant of the code detail
    }

    /// The number of views models that are currently held in cache.
    var cachedViewsCount: Int {
        viewModelCache.count
    }

    var cachedTimerControllerCount: Int {
        timerUpdaterCache.count
    }

    var cachedPeriodStateCount: Int {
        timerPeriodStateCache.count
    }

    private func makeTimerController(period: UInt64) -> any OTPCodeTimerUpdater {
        timerUpdaterCache.getOrCreateValue(for: period) {
            updaterFactory.makeUpdater(period: period)
        }
    }

    private func makeTimerPeriodState(period: UInt64) -> OTPCodeTimerPeriodState {
        timerPeriodStateCache.getOrCreateValue(for: period) {
            let timerController = makeTimerController(period: period)
            return OTPCodeTimerPeriodState(clock: clock, statePublisher: timerController.timerUpdatedPublisher())
        }
    }

    private func makeViewModelForCode(
        id: UUID,
        code: TOTPAuthCode
    ) -> OTPCodePreviewViewModel {
        viewModelCache.getOrCreateValue(for: id) {
            let totpGenerator = TOTPGenerator(generator: code.data.hotpGenerator(), timeInterval: code.period)
            let renderer = TOTPCodeRenderer(
                timer: makeTimerController(period: code.period),
                totpGenerator: totpGenerator
            )
            return OTPCodePreviewViewModel(
                accountName: code.data.accountName,
                issuer: code.data.issuer,
                renderer: renderer
            )
        }
    }
}
