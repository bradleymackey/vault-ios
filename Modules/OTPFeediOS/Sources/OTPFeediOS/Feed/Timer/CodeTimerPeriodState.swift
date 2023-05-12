import Combine
import Foundation
import OTPFeed

/// Tracks the state for a given timer period.
///
/// As all timers with the same period share the same state at any given time,
/// they can refer to this single object for fetching the latest state.
@MainActor
final class CodeTimerPeriodState: ObservableObject {
    @Published private(set) var state: OTPTimerState?

    init() {}
}
