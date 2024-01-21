import Foundation

public struct DataBlockDocument {
    /// Header generator for a given page number.
    public var headerGenerator: any DataBlockHeaderGenerator
    public var titles: [DataBlockLabel]
    public var dataBlockImageData: [Data]

    public init(
        headerGenerator: any DataBlockHeaderGenerator = NoHeaderDataBlockHeaderGenerator(),
        titles: [DataBlockLabel] = [],
        dataBlockImageData: [Data]
    ) {
        self.headerGenerator = headerGenerator
        self.titles = titles
        self.dataBlockImageData = dataBlockImageData
    }
}
