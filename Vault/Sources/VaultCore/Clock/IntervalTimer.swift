import Combine
import Foundation

public protocol IntervalTimer {
    /// Set an expectation to publish once after the specified `time`.
    func wait(for time: Double) -> AnyPublisher<Void, Never>
}

// MARK: - Mock

public final class IntervalTimerMock: IntervalTimer {
    private let waitSubject = PassthroughSubject<Void, Never>()
    /// Mock: the intervals that were waited for.
    public var waitArgValues = [Double]()

    public init() {}

    public func finishTimer() {
        waitSubject.send()
    }

    public func wait(for time: Double) -> AnyPublisher<Void, Never> {
        waitArgValues.append(time)
        return waitSubject.first().eraseToAnyPublisher()
    }
}

// MARK: - Impl

/// A timer that actually waits for the specified interval.
public final class IntervalTimerImpl: IntervalTimer {
    public init() {}
    public func wait(for time: Double) -> AnyPublisher<Void, Never> {
        Timer.TimerPublisher(interval: time, runLoop: .current, mode: .common)
            .autoconnect()
            .map { _ in }
            .first() // only publish once
            .eraseToAnyPublisher()
    }
}
