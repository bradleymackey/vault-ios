import Foundation

/// A `LocalResourceFetcher` that returns `stubData` instead of actually fetching the file from disk.
public struct StubLocalResourceFetcher: LocalResourceFetcher {
    private let stubData: Data
    public init(stubData: Data) {
        self.stubData = stubData
    }

    public func fetchLocalResource(at _: URL) throws -> Data {
        stubData
    }

    public func fetchLocalResource(fromBundle _: Bundle, fileName _: String, fileExtension _: String) throws -> Data {
        stubData
    }
}
