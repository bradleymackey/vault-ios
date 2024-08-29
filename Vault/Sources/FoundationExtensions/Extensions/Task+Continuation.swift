import Foundation

extension Task where Failure == Never {
    /// Creates a continuation task that runs within the current task.
    ///
    /// Checks for cancellation just before the continuation is resumed.
    public static func continuation(
        priority: TaskPriority? = nil,
        body: @Sendable @escaping () throws -> Success
    ) async throws -> Success {
        try await withCheckedThrowingContinuation { cont in
            Task<Void, Never>.detached(priority: priority) {
                do {
                    let result = try body()
                    try Task<Never, Never>.checkCancellation()
                    cont.resume(returning: result)
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }
}
