import Foundation

public protocol LocalResourceFetcher {
    /// Fetches a local resource, returning the data.
    func fetchLocalResource(at url: URL) throws -> Data
}
