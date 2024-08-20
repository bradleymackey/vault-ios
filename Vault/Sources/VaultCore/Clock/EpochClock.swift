import Combine
import Foundation

/// Epoch clock that derives the time from the injected time.
///
/// The clock has reference semantics, as multiple consumers may want to reference the same clock instance.
public final class EpochClock {
    public var makeCurrentTime: () -> Double

    public init(makeCurrentTime: @escaping () -> Double) {
        self.makeCurrentTime = makeCurrentTime
    }

    public var currentTime: Double {
        makeCurrentTime()
    }

    public var currentDate: Date {
        Date(timeIntervalSince1970: currentTime)
    }
}
