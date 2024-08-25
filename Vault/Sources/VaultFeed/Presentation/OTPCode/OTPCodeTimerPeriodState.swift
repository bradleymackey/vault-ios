import Combine
import Foundation

/// Tracks the state for a given timer period.
///
/// As all timers with the same period share the same state at any given time,
/// they can refer to this single object for fetching the latest state.
@MainActor
@Observable
public final class OTPCodeTimerPeriodState {
    public private(set) var animationState: OTPCodeTimerAnimationState = .freeze(fraction: 0)

    private var stateCancellable: AnyCancellable?

    public init(statePublisher: AnyPublisher<OTPCodeTimerState, Never>) {
        stateCancellable = statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.animationState = .countdownFrom(timerState: state)
            }
    }
}
