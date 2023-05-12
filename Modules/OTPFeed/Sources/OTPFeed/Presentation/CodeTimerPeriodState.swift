import Combine
import Foundation

/// Tracks the state for a given timer period.
///
/// As all timers with the same period share the same state at any given time,
/// they can refer to this single object for fetching the latest state.
@MainActor
final class CodeTimerPeriodState: ObservableObject {
    @Published private(set) var state: OTPTimerState?

    private var stateCancellable: AnyCancellable?

    init(statePublisher: AnyPublisher<OTPTimerState, Never>) {
        stateCancellable = statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.state = state
            }
    }
}
