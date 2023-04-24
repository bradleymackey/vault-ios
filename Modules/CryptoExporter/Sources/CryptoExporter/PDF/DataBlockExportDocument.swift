import Foundation

public struct DataBlockExportDocument {
    public var title: DataBlockLabel?
    public var subtitle: DataBlockLabel?
    public var dataBlockImageData: [Data]

    public init(title: DataBlockLabel? = nil, subtitle: DataBlockLabel? = nil, dataBlockImageData: [Data]) {
        self.title = title
        self.subtitle = subtitle
        self.dataBlockImageData = dataBlockImageData
    }
}
