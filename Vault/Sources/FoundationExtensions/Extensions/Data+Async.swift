import Foundation

extension Data {
    /// Fetches contents of a given URL in the background, without blocking the current actor.
    public init(asyncContentsOf url: URL) async throws {
        self = try await Task.background {
            try Data(contentsOf: url)
        }
    }
}
