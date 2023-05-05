import Combine
import Foundation

public protocol IntervalTimer {
    /// Set an expectation to publish once after the specified `time`.
    func wait(for time: Double) -> AnyPublisher<Void, Never>
}
