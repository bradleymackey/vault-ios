import Combine
import Foundation
import FoundationExtensions

/// A clock that reports the current time.
///
/// This is a protocol so that we can inject clocks time values where needed.
public protocol EpochClock: Sendable {
    var currentTime: Double { get }
}

extension EpochClock {
    public var currentDate: Date {
        Date(timeIntervalSince1970: currentTime)
    }
}

/// Mock clock where the current time can be updated.
///
/// This is a reference type, so can be shared and is useful for injecting.
public final class EpochClockMock: EpochClock {
    /// Thread-safe storage value for the current time.
    private let currentTimeProvider: Atomic<Double>

    public init(currentTime: Double) {
        currentTimeProvider = .init(initialValue: currentTime)
    }

    public var currentTime: Double {
        get {
            currentTimeProvider.get { $0 }
        }
        set {
            currentTimeProvider.modify { $0 = newValue }
        }
    }
}

extension EpochClock where Self == EpochClockMock {
    public static func mocked(initialTime: Double) -> EpochClockMock {
        .init(currentTime: initialTime)
    }
}

/// Epoch clock that is equal to the current time, according to the device.
public struct EpochClockImpl: EpochClock {
    public init() {}

    public var currentTime: Double {
        Date.now.timeIntervalSince1970
    }

    public var currentDate: Date {
        Date.now
    }
}
