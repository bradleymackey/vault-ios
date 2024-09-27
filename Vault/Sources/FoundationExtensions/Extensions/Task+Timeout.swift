import Foundation

extension Task where Failure == any Error {
    /// Creates a task that will timeout after the specified duration.
    /// The Task will throw a `TimeoutError` if the timeout is reached before
    /// the `task` completes.
    public static func withTimeout(
        delay: Duration,
        priority: TaskPriority? = nil,
        task: @escaping TaskRace<Success>
    ) -> Task<Success, any Error> {
        Task.race(priority: priority, firstResolved: [
            {
                try await Task<Never, Never>.sleep(for: delay)
                throw TimeoutError()
            },
            task,
        ])
    }
}
