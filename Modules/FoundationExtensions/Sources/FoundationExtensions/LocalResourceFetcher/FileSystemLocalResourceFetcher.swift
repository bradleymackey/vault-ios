import Foundation

/// A `LocalResourceFetcher` that actually fetches the file from disk.
public struct FileSystemLocalResourceFetcher: LocalResourceFetcher {
    public init() {}
    public func fetchLocalResource(at url: URL) throws -> Data {
        try Data(contentsOf: url)
    }
}
