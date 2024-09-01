import Combine
import Foundation
import FoundationExtensions

public protocol IntervalTimer: Sendable {
    /// Set an expectation to publish once after the specified `time`.
    func wait(for time: Double) -> AnyPublisher<Void, Never>
    /// Set an expectation to publish once after the specified `time`, with tolerance.
    func wait(for time: Double, tolerance: Double) -> AnyPublisher<Void, Never>
    /// Set an expectation to resume after the specified `time`.
    ///
    /// Responds to cancellation, throwing a `CancellationError`.
    func wait(for time: Double) async throws
    /// Set an expectation to resume after the specified `time`, with tolerance.
    ///
    /// Responds to cancellation, throwing a `CancellationError`.
    func wait(for time: Double, tolerance: Double) async throws
}

extension IntervalTimer {
    /// Schedules a task to run after the specified delay.
    @discardableResult
    public func schedule<T>(
        priority: TaskPriority = .medium,
        wait time: Double,
        tolerance: Double? = nil,
        work: @Sendable @escaping () async throws -> T
    ) -> Task<T, any Error> {
        Task(priority: priority) {
            if let tolerance {
                try await wait(for: time, tolerance: tolerance)
            } else {
                try await wait(for: time)
            }
            return try await work()
        }
    }
}

// MARK: - Mock

public final class IntervalTimerMock: IntervalTimer {
    private let waitSubject = Atomic<PassthroughSubject<Void, Never>>(initialValue: .init())
    /// Mock: the intervals that were waited for.
    private let waitArgValuesData = Atomic<[Double]>(initialValue: [])
    private let pendingTimer = Atomic<PendingValue<Void>?>(initialValue: nil)

    public var waitArgValues: [Double] {
        waitArgValuesData.get { $0 }
    }

    public init() {}

    public func finishTimer() async {
        waitSubject.get { $0 }.send()
        await pendingTimer.value?.fulfill()
        await Task.yield()
    }

    public func wait(for time: Double) async throws {
        waitArgValuesData.modify { $0.append(time) }
        pendingTimer.modify { $0 = PendingValue() }
        try await pendingTimer.value?.awaitValue()
    }

    public func wait(for time: Double, tolerance _: Double) async throws {
        waitArgValuesData.modify { $0.append(time) }
        pendingTimer.modify { $0 = PendingValue() }
        try await pendingTimer.value?.awaitValue()
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

    public func wait(for time: Double) async throws {
        try await Task.sleep(for: .seconds(time), clock: .continuous)
    }

    public func wait(for time: Double, tolerance: Double) async throws {
        try await Task.sleep(for: .seconds(time), tolerance: .seconds(tolerance), clock: .continuous)
    }
}
