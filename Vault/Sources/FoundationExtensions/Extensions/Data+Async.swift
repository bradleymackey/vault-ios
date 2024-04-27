import Foundation

extension Data {
    /// Fetches contents of a given URL in the background, without blocking the current actor.
    public init(asyncContentsOf url: URL) async throws {
        self = try await withCheckedThrowingContinuation { continuation in
            Task.detached(priority: .background) {
                continuation.resume(with: Result {
                    try Data(contentsOf: url)
                })
            }
        }
    }
}
