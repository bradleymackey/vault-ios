import Combine
import Foundation

public protocol IntervalTimer {
    /// Set an expectation to publish once after the specified `time`.
    func wait(for time: Double) -> AnyPublisher<Void, Never>
    /// Set an expectation to publish once after the specified `time`, with tolerance.
    func wait(for time: Double, tolerance: Double) -> AnyPublisher<Void, Never>
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

    public func wait(for time: Double, tolerance _: Double) -> AnyPublisher<Void, Never> {
        waitArgValues.append(time)
        return waitSubject.first().eraseToAnyPublisher()
    }
}

// MARK: - Impl

/// A timer that actually waits for the specified interval.
public final class IntervalTimerImpl: IntervalTimer {
    public init() {}
    public func wait(for time: Double) -> AnyPublisher<Void, Never> {
        waitPublisher(for: time, tolerance: nil)
    }

    public func wait(for time: Double, tolerance: Double) -> AnyPublisher<Void, Never> {
        waitPublisher(for: time, tolerance: tolerance)
    }

    private func waitPublisher(for time: Double, tolerance: Double?) -> AnyPublisher<Void, Never> {
        Timer.TimerPublisher(interval: time, tolerance: tolerance, runLoop: .main, mode: .common)
            .autoconnect()
            .map { _ in }
            .first() // only publish once
            .eraseToAnyPublisher()
    }
}
