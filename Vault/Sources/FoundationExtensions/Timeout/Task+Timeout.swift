import Foundation

extension Task where Failure == any Error {
    /// Race the given `task` against a timeout for the specified `delay`.
    /// The Task will throw a `TimeoutError` if the timeout is reached before
    /// the `task` completes.
    ///
    /// This uses `Task.race` internally. The task should respond well to `CancellationError`.
    public static func withTimeout(
        delay: Duration,
        priority: TaskPriority? = nil,
        timeoutID: UUID = UUID(),
        task: @escaping TaskRace<Success>,
    ) async throws -> Success {
        try await Task.race(priority: priority, firstResolved: [
            task,
            { try await Task<Never, TimeoutError>.timeout(in: delay, id: timeoutID) },
        ])
    }
}

extension Task where Success == Never, Failure == TimeoutError {
    /// Throws a `TimeoutError` after `duration`. Never returns.
    public static func timeout(in duration: Duration, id: UUID = UUID()) async throws -> Never {
        try await Task<Never, Never>.sleep(for: duration)
        try Task<Never, Never>.checkCancellation()
        throw TimeoutError(id: id)
    }
}
