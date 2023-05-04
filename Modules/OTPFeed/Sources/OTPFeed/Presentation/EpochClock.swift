import Combine
import Foundation

/// A clock that ticks once a second, based on the UNIX epoch.
public protocol EpochClock {
    func secondsPublisher() -> AnyPublisher<UInt64, Never>
    /// The current time, as most recently published.
    var currentTime: UInt64 { get }
}
