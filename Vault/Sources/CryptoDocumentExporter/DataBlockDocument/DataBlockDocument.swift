import Foundation

public struct DataBlockDocument {
    /// Header generator for a given page number.
    public var headerGenerator: any DataBlockHeaderGenerator
    /// The content to be drawn to the document, in the order provided here.
    public var content: [Content]

    /// Content that can be rendered to the document.
    public enum Content: CustomDebugStringConvertible {
        /// A piece of text rendered as a label.
        case title(DataBlockLabel)
        /// A series of images, which will draw the PNG data to the document as a sqaure, tiling the images.
        case images([Data])

        public var debugDescription: String {
            switch self {
            case let .title(label): "TITLE: \(label.text)"
            case let .images(data): "IMAGE: \(data)"
            }
        }
    }

    public init(
        headerGenerator: any DataBlockHeaderGenerator = NoHeaderDataBlockHeaderGenerator(),
        content: [Content]
    ) {
        self.headerGenerator = headerGenerator
        self.content = content
    }
}
