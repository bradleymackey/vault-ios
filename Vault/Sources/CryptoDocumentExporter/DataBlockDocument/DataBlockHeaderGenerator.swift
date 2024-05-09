import Foundation

/// Creates a header for a given page when generating a document.
/// @mockable
public protocol DataBlockHeaderGenerator {
    func makeHeader(pageNumber: Int) -> DataBlockHeader?
}

// MARK: - Impls

extension DataBlockHeaderGenerator {
    static var noHeader: any DataBlockHeaderGenerator {
        NoHeaderDataBlockHeaderGenerator()
    }
}

public struct NoHeaderDataBlockHeaderGenerator: DataBlockHeaderGenerator {
    public init() {}
    public func makeHeader(pageNumber _: Int) -> DataBlockHeader? {
        nil
    }
}
