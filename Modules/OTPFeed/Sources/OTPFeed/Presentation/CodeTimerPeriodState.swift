import Combine
import Foundation
import OTPCore

/// Tracks the state for a given timer period.
///
/// As all timers with the same period share the same state at any given time,
/// they can refer to this single object for fetching the latest state.
@MainActor
public final class CodeTimerPeriodState: ObservableObject {
    @Published public private(set) var state: OTPTimerState?

    private let clock: EpochClock
    private var stateCancellable: AnyCancellable?

    public init(clock: EpochClock, statePublisher: AnyPublisher<OTPTimerState, Never>) {
        self.clock = clock
        stateCancellable = statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.state = state
            }
    }

    /// Creates a countdown animation from the current state of the timer.
    public func countdownAnimation() -> CodeTimerAnimationState {
        CodeTimerAnimationState.countdownFrom(
            timerState: state,
            currentTime: clock.currentTime
        )
    }
}
