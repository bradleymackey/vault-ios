import Combine
import Foundation
import VaultCore

/// Tracks the state for a given timer period.
///
/// As all timers with the same period share the same state at any given time,
/// they can refer to this single object for fetching the latest state.
@Observable
public final class OTPCodeTimerPeriodState {
    public private(set) var animationState: OTPCodeTimerAnimationState = .freeze(fraction: 0)

    private var stateCancellable: AnyCancellable?

    public init(clock _: EpochClock, statePublisher: AnyPublisher<OTPCodeTimerState, Never>) {
        stateCancellable = statePublisher
            .sink { [weak self] state in
                self?.animationState = .countdownFrom(timerState: state)
            }
    }
}
