import Combine
import Foundation
import FoundationExtensions

public protocol EpochClock: Sendable {
    var currentTime: Double { get }
}

extension EpochClock {
    public var currentDate: Date {
        Date(timeIntervalSince1970: currentTime)
    }
}

/// Mock clock where access to the current time value is protected by a lock.
///
/// This is useful for stubbing out times in a mutable, thread-safe way.
public final class EpochClockMock: EpochClock {
    /// Thread-safe storage value for the current time.
    public let currentTimeProvider: Atomic<Double>

    public var currentTime: Double {
        currentTimeProvider.get { $0 }
    }

    public init(currentTime: Double) {
        currentTimeProvider = .init(initialValue: currentTime)
    }
}

/// Epoch clock that derives the time from the injected time.
///
/// The clock has reference semantics, as multiple consumers may want to reference the same clock instance.
public final class EpochClockImpl: EpochClock {
    public let makeCurrentTime: @Sendable () -> Double

    public init(makeCurrentTime: @escaping @Sendable () -> Double) {
        self.makeCurrentTime = makeCurrentTime
    }

    public var currentTime: Double {
        makeCurrentTime()
    }

    public var currentDate: Date {
        Date(timeIntervalSince1970: currentTime)
    }
}
