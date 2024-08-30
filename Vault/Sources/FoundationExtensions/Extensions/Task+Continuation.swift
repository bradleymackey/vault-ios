import Foundation

extension Task where Failure == Never {
    /// Creates a continuation task that runs as a detached `Task`.
    ///
    /// Checks for cancellation just before the continuation is resumed.
    /// If it's cancelled, it will throw a standard `CancellationError`.
    public static func continuation(
        priority: TaskPriority? = nil,
        body: @Sendable @escaping () throws -> Success
    ) async throws -> Success {
        // The atomic here does not violate the SC model as it never blocks.
        // It's just for safely cancelling the task.
        let runningTask: Atomic<Task<Void, Never>?> = .init(initialValue: nil)
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { cont in
                let task = Task<Void, Never>.detached(priority: priority) {
                    do {
                        let result = try body()
                        try Task<Never, Never>.checkCancellation()
                        cont.resume(returning: result)
                    } catch {
                        cont.resume(throwing: error)
                    }
                }
                runningTask.modify { $0 = task }
            }
        } onCancel: {
            runningTask.modify { $0?.cancel() }
        }
    }
}
