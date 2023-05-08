import Combine
import Foundation

/// A timer that actually waits for the specified interval.
public struct LiveIntervalTimer: IntervalTimer {
    public init() {}
    public func wait(for time: Double) -> AnyPublisher<Void, Never> {
        Timer.TimerPublisher(interval: time, runLoop: .current, mode: .common)
            .autoconnect()
            .map { _ in }
            .first() // only publish once
            .eraseToAnyPublisher()
    }
}
