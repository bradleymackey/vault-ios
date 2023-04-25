import Foundation

public struct DataBlockExportDocument {
    public var titles: [DataBlockLabel]
    public var dataBlockImageData: [Data]

    public init(titles: [DataBlockLabel] = [], dataBlockImageData: [Data]) {
        self.titles = titles
        self.dataBlockImageData = dataBlockImageData
    }
}
