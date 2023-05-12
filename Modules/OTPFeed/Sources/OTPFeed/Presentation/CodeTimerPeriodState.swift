import Combine
import Foundation

/// Tracks the state for a given timer period.
///
/// As all timers with the same period share the same state at any given time,
/// they can refer to this single object for fetching the latest state.
@MainActor
public final class CodeTimerPeriodState: ObservableObject {
    @Published public private(set) var state: OTPTimerState?

    private var stateCancellable: AnyCancellable?

    public init(statePublisher: AnyPublisher<OTPTimerState, Never>) {
        stateCancellable = statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.state = state
            }
    }
}
