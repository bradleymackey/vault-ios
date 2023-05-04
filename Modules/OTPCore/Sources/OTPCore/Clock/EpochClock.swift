import Combine
import Foundation

/// A clock that ticks once a second, based on the UNIX epoch.
public protocol EpochClock {
    /// Force the clock to tick the current time.
    func tick()
    /// Publishes on ticks or by the clock's own heuristics.
    func secondsPublisher() -> AnyPublisher<Double, Never>
    /// The current time, as most recently published.
    var currentTime: Double { get }
}
