import Combine
import Foundation

public protocol IntervalClock {
    /// Set an expectation to publish once after the specified `time`.
    func timerPublisher(time: Double) -> AnyPublisher<Void, Never>
}
