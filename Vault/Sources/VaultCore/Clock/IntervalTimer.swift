import Foundation
import FoundationExtensions

public protocol IntervalTimer: Sendable {
    /// Set an expectation to resume after the specified `time`.
    ///
    /// Responds to cancellation, throwing a `CancellationError`.
    func wait(for time: Double) async throws
    /// Set an expectation to resume after the specified `time`, with tolerance.
    ///
    /// Responds to cancellation, throwing a `CancellationError`.
    func wait(for time: Double, tolerance: Double) async throws

    /// Schedules a task to run after the specified delay.
    func schedule<T>(
        priority: TaskPriority,
        wait time: Double,
        tolerance: Double?,
        work: @Sendable @escaping () async throws -> T
    ) -> Task<T, any Error>
}

extension IntervalTimer {
    /// Schedules a task to run after the specified delay.
    public func schedule<T: Sendable>(
        priority: TaskPriority = .medium,
        wait time: Double,
        work: @Sendable @escaping () async throws -> T
    ) -> Task<T, any Error> {
        schedule(priority: priority, wait: time, tolerance: nil, work: work)
    }
}

// MARK: - Mock

public final class IntervalTimerMock: IntervalTimer {
    /// Mock: the intervals that were waited for.
    private let waitArgValuesData = SharedMutex<[Double]>([])
    private let pendingTimer = SharedMutex<Pending<Void>?>(nil)
    private let pendingSchedules = SharedMutex<Int>(0)

    public var waitArgValues: [Double] {
        waitArgValuesData.get { $0 }
    }

    public init() {}

    public func finishTimer() async {
        // Finishing a timer runs at a low priority, so timer scheduling and work execution always takes priority
        let finishTask = Task.detached(priority: .low) {
            await Task.yield() // give time for any `schedule` blocks to be created
            await self.pendingTimer.value?.fulfill()
            while self.pendingSchedules.value > 0 {
                await Task.yield() // allow time for scheduled blocks to complete
            }
        }
        await finishTask.value
    }

    public func wait(for time: Double) async throws {
        waitArgValuesData.modify { $0.append(time) }
        pendingTimer.modify { $0 = Pending() }
        defer { pendingTimer.modify { $0 = nil } }
        try await pendingTimer.value?.wait()
    }

    public func wait(for time: Double, tolerance _: Double) async throws {
        waitArgValuesData.modify { $0.append(time) }
        pendingTimer.modify { $0 = Pending() }
        defer { pendingTimer.modify { $0 = nil } }
        try await pendingTimer.value?.wait()
    }

    public func schedule<T: Sendable>(
        wait time: Double,
        work: @Sendable @escaping () async throws -> T
    ) -> Task<T, any Error> {
        schedule(priority: .medium, wait: time, tolerance: nil, work: work)
    }

    public func schedule<T: Sendable>(
        priority: TaskPriority,
        wait _: Double,
        tolerance _: Double?,
        work: @Sendable @escaping () async throws -> T
    ) -> Task<T, any Error> {
        pendingSchedules.modify { $0 += 1 }
        return Task.detached(priority: .high) {
            defer { self.pendingSchedules.modify { $0 -= 1 } }
            await self.pendingTimer.value?.fulfill()
            let work = Task(priority: priority) {
                try await work()
            }
            return try await work.value
        }
    }
}

// MARK: - Impl

/// A timer that actually waits for the specified interval.
public final class IntervalTimerImpl: IntervalTimer {
    public init() {}

    public func wait(for time: Double) async throws {
        try await Task.sleep(for: .seconds(time), clock: .continuous)
    }

    public func wait(for time: Double, tolerance: Double) async throws {
        try await Task.sleep(for: .seconds(time), tolerance: .seconds(tolerance), clock: .continuous)
    }

    public func schedule<T>(
        priority: TaskPriority,
        wait time: Double,
        tolerance: Double?,
        work: @Sendable @escaping () async throws -> T
    ) -> Task<T, any Error> {
        // Performing the waiting is high priority, so we are sure this is scheduled ASAP.
        Task.detached(priority: .high) {
            if let tolerance {
                try await self.wait(for: time, tolerance: tolerance)
            } else {
                try await self.wait(for: time)
            }
            // The actual work runs with the user-specified priority.
            let work = Task(priority: priority) {
                try await work()
            }
            return try await work.value
        }
    }

    public func schedule<T: Sendable>(
        wait time: Double,
        work: @Sendable @escaping () async throws -> T
    ) -> Task<T, any Error> {
        schedule(priority: .medium, wait: time, tolerance: nil, work: work)
    }
}
