import Combine
import Foundation

public protocol IntervalClock {
    /// Publishes at the specified interval, then finishes.
    func timerPublisher(interval: Double) -> AnyPublisher<Void, Never>
}
