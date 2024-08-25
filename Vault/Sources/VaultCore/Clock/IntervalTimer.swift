import Combine
import Foundation
import FoundationExtensions

public protocol IntervalTimer: Sendable {
    /// Set an expectation to publish once after the specified `time`.
    func wait(for time: Double) -> AnyPublisher<Void, Never>
    /// Set an expectation to publish once after the specified `time`, with tolerance.
    func wait(for time: Double, tolerance: Double) -> AnyPublisher<Void, Never>
}

// MARK: - Mock

public final class IntervalTimerMock: IntervalTimer {
    private let waitSubject = Atomic<PassthroughSubject<Void, Never>>(initialValue: .init())
    /// Mock: the intervals that were waited for.
    private let waitArgValuesData = Atomic<[Double]>(initialValue: [])

    public var waitArgValues: [Double] {
        waitArgValuesData.get { $0 }
    }

    public init() {}

    public func finishTimer() {
        waitSubject.get { $0 }.send()
    }

    public func wait(for time: Double) -> AnyPublisher<Void, Never> {
        waitArgValuesData.modify { $0.append(time) }
        return waitSubject.get { $0 }.first().eraseToAnyPublisher()
    }

    public func wait(for time: Double, tolerance _: Double) -> AnyPublisher<Void, Never> {
        waitArgValuesData.modify { $0.append(time) }
        return waitSubject.get { $0 }.first().eraseToAnyPublisher()
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
