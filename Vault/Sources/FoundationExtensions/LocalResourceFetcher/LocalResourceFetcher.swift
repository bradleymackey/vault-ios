import Foundation

public protocol LocalResourceFetcher {
    /// Fetches a local resource, returning the data.
    func fetchLocalResource(at url: URL) async throws -> Data
    /// Fetches a local resource in the context of the given `Bundle`.
    func fetchLocalResource(fromBundle bundle: Bundle, fileName: String, fileExtension: String) async throws -> Data
}
