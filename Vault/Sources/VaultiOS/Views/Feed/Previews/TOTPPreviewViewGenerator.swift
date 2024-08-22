import Combine
import CryptoEngine
import SwiftUI
import VaultFeed

/// An efficient generator of preview views for TOTP codes.
///
/// Internal caching and sharing of models and timers makes this very efficient.
@MainActor
final class TOTPPreviewViewGenerator<Factory: TOTPPreviewViewFactory>: VaultItemPreviewViewGenerator {
    typealias PreviewItem = TOTPAuthCode

    private let viewFactory: Factory
    private let updaterFactory: any OTPCodeTimerUpdaterFactory
    private let clock: EpochClock
    private let timer: any IntervalTimer
    private var timerUpdaterCache = Cache<UInt64, any OTPCodeTimerUpdater>()
    private var timerPeriodStateCache = Cache<UInt64, OTPCodeTimerPeriodState>()
    private var viewModelCache = Cache<Identifier<VaultItem>, OTPCodePreviewViewModel>()

    init(
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

    func makeVaultPreviewView(
        item: PreviewItem,
        metadata: VaultItem.Metadata,
        behaviour: VaultItemViewBehaviour
    ) -> some View {
        viewFactory.makeTOTPView(
            viewModel: makeViewModelForCode(metadata: metadata, code: item),
            periodState: makeTimerPeriodState(period: item.period),
            updater: makeTimerController(period: item.period),
            behaviour: behaviour
        )
    }

    func scenePhaseDidChange(to scene: ScenePhase) {
        if scene == .active {
            recalculateAllTimers()
        }
    }

    func didAppear() {
        recalculateAllTimers()
    }
}

extension TOTPPreviewViewGenerator {
    func recalculateAllTimers() {
        for timerUpdater in timerUpdaterCache.values {
            timerUpdater.recalculate()
        }
    }
}

extension TOTPPreviewViewGenerator: VaultItemPreviewActionHandler, VaultItemCopyActionHandler {
    func previewActionForVaultItem(id: Identifier<VaultItem>) -> VaultItemPreviewAction? {
        guard let visibleCode = textToCopyForVaultItem(id: id) else { return nil }
        return .copyText(visibleCode)
    }

    func textToCopyForVaultItem(id: Identifier<VaultItem>) -> String? {
        viewModelCache[id]?.code.visibleCode
    }
}

// MARK: - Caching

extension TOTPPreviewViewGenerator: VaultItemCache {
    func invalidateVaultItemDetailCache(forVaultItemWithID id: Identifier<VaultItem>) {
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
            return OTPCodeTimerPeriodState(statePublisher: timerController.timerUpdatedPublisher())
        }
    }

    private func makeViewModelForCode(
        metadata: VaultItem.Metadata,
        code: TOTPAuthCode
    ) -> OTPCodePreviewViewModel {
        viewModelCache.getOrCreateValue(for: metadata.id) {
            let totpGenerator = TOTPGenerator(generator: code.data.hotpGenerator(), timeInterval: code.period)
            let renderer = TOTPCodeRenderer(
                timer: makeTimerController(period: code.period),
                totpGenerator: totpGenerator
            )
            return OTPCodePreviewViewModel(
                accountName: code.data.accountName,
                issuer: code.data.issuer,
                color: metadata.color ?? .default,
                renderer: renderer
            )
        }
    }
}
