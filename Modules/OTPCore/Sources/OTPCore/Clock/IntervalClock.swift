import Combine
import Foundation

public protocol IntervalClock {
    /// Publishes at the specified interval.
    /// `Output` is the number of seconds since the epoch.
    func timerPublisher(interval: Double) -> AnyPublisher<Double, Never>
}
