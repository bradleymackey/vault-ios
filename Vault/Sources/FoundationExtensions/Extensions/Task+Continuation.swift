import Foundation

extension Task where Failure == Never {
    /// Creates a continuation task that runs as a detached `Task`.
    ///
    /// Checks for cancellation just before the continuation is resumed.
    /// If it's cancelled before the sync task is scheduled to run, it will throw a standard `CancellationError`.
    ///
    /// If the task is cancelled during, or after the sync task has been scheduled, the task will not throw any
    /// cancellation error. You should explcitly check for cancellation after running if this is desired.
    public static func continuation(
        priority: TaskPriority? = nil,
        body: @Sendable @escaping () throws -> Success
    ) async throws -> Success {
        // The atomic here does not violate the SC model as it never blocks.
        // It's just for safely cancelling the task.
        let isCancelled = SharedMutex<Bool>(false)
        let runningTask = SharedMutex<Task<Void, Never>?>(nil)
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { cont in
                let task = Task<Void, Never>.detached(priority: priority) {
                    cont.resume(with: Result {
                        try computeContinuationResult(isCancelled: isCancelled, body: body)
                    })
                }
                runningTask.modify { $0 = task }
            }
        } onCancel: {
            isCancelled.modify { $0 = true }
            runningTask.modify { $0?.cancel() }
        }
    }
}

private func computeContinuationResult<T>(
    isCancelled: SharedMutex<Bool>,
    body: @Sendable @escaping () throws -> T
) throws -> T {
    guard !isCancelled.value else { throw CancellationError() }
    return try body()
}
