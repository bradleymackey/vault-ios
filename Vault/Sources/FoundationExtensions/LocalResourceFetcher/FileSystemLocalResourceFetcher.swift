import Foundation

/// A `LocalResourceFetcher` that actually fetches the file from disk.
public struct FileSystemLocalResourceFetcher: LocalResourceFetcher {
    public init() {}

    public func fetchLocalResource(at url: URL) throws -> Data {
        try Data(contentsOf: url)
    }

    public func fetchLocalResource(fromBundle bundle: Bundle, fileName: String, fileExtension: String) throws -> Data {
        guard let url = bundle.url(forResource: fileName, withExtension: fileExtension) else {
            throw LocalResourceFetcherError.fileDoesNotExist
        }
        return try fetchLocalResource(at: url)
    }
}
