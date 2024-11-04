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
    /// Mock: the scheduled actions that will wait for `finishTimer` to be called.
    /// This allows the mock timer to just suspend until the test wants the timer to finish.
    private let waits = SharedMutex<[Pending<Void>]>([])
    /// Mock: optional for each wait. If we want to wait for
    private let completions = SharedMutex<[UUID: Pending<Void>]>([:])

    public var waitArgValues: [Double] {
        waitArgValuesData.get { $0 }
    }

    public init() {}

    /// Finishes the timer at the specified index.
    ///
    /// The index corresponds to the relative order that the 'wait' or 'schedule' was requested.
    public func finishTimer(at index: Int = 0) async {
        // Finishing a timer runs at a low priority, so timer scheduling and work execution always takes priority
        let finishTask = Task.detached(priority: .low) {
            await Task.yield() // give time for any `schedule` blocks to be created
            precondition(
                self.waits.value.indices.contains(index),
                "Cannot finishTimer, there was no wait at index \(index)!"
            )
            let waiter = self.waits.get { $0[index] }
            await waiter.fulfill()
            // Now, if there is an assocaiated completion action, wait for it to finish.
            let associatedCompletion = self.completions.get { $0[waiter.id] }
            try? await associatedCompletion?.wait()
            await Task.yield() // allow time for a bit of cleanup
        }
        await finishTask.value
    }

    public func wait(for time: Double) async throws {
        waitArgValuesData.modify { $0.append(time) }
        let newPending = Pending.signal()
        waits.modify { $0.append(newPending) }
        try await newPending.wait()
    }

    public func wait(for time: Double, tolerance _: Double) async throws {
        waitArgValuesData.modify { $0.append(time) }
        let newPending = Pending.signal()
        waits.modify { $0.append(newPending) }
        try await newPending.wait()
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
        let newPending = Pending.signal()
        waits.modify { $0.append(newPending) }
        let completion = Pending.signal()
        completions.modify { $0[newPending.id] = completion }
        return Task.detached(priority: priority) {
            defer {
                Task { await completion.fulfill() }
            }

            try await newPending.wait()
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
