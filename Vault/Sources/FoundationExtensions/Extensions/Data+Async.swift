import Foundation

extension Data {
    /// Fetches contents of a given URL in the background, without blocking the current actor.
    public init(asyncContentsOf url: URL) async throws {
        self = try await Task.continuation(priority: .background) {
            try Data(contentsOf: url)
        }
    }
}
