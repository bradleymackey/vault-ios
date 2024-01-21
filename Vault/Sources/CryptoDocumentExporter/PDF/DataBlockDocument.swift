import Foundation

public struct DataBlockDocument {
    /// Header generator for a given page number.
    public var headerForPage: (Int) -> DataBlockHeader?
    public var titles: [DataBlockLabel]
    public var dataBlockImageData: [Data]

    public init(
        headerForPage: @escaping (Int) -> DataBlockHeader?,
        titles: [DataBlockLabel] = [],
        dataBlockImageData: [Data]
    ) {
        self.headerForPage = headerForPage
        self.titles = titles
        self.dataBlockImageData = dataBlockImageData
    }
}
