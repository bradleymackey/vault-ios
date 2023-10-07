import Foundation

public protocol LocalResourceFetcher {
    /// Fetches a local resource, returning the data.
    func fetchLocalResource(at url: URL) throws -> Data
}

/// A concrete implementation of `LocalResourceFetcher` that actually fetches the file from disk.
public struct FileSystemLocalResourceFetcher: LocalResourceFetcher {
    public init() {}
    public func fetchLocalResource(at url: URL) throws -> Data {
        try Data(contentsOf: url)
    }
}
