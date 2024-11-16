import Foundation

extension Task where Failure == any Error {
    /// Runs some work on a new background task, nonisolated from the current parent task.
    ///
    /// This is useful for heavy background work that is triggered from a higher priority task/actor.
    /// For example, starting some long-running work from the `MainActor` that we don't want to block the `MainActor`.
    ///
    /// If the parent task is cancelled, this will propagate to this task as well, throwing `CancellationError` at the
    /// body's discretion.
    public static func background(body: @Sendable @escaping () async throws(Failure) -> Success) async throws(Failure)
        -> Success
    {
        let runningTask = SharedMutex<Task<Success, Failure>?>(nil)
        return try await withTaskCancellationHandler {
            let task = Task.detached(priority: .background) {
                try await body()
            }
            runningTask.modify { $0 = task }
            try Task<Never, Never>.checkCancellation()
            return try await task.value
        } onCancel: {
            runningTask.modify { $0?.cancel() }
        }
    }
}
