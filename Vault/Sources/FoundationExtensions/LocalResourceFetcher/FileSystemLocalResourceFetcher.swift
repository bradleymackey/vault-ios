import Foundation

/// A `LocalResourceFetcher` that actually fetches the file from disk.
public struct FileSystemLocalResourceFetcher: LocalResourceFetcher, Sendable {
    public init() {}

    public func fetchLocalResource(at url: URL) async throws -> Data {
        try await Data(asyncContentsOf: url)
    }

    public func fetchLocalResource(
        fromBundle bundle: Bundle,
        fileName: String,
        fileExtension: String,
    ) async throws -> Data {
        guard let url = bundle.url(forResource: fileName, withExtension: fileExtension) else {
            throw LocalResourceFetcherError.fileDoesNotExist
        }
        return try await fetchLocalResource(at: url)
    }
}
