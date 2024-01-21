import Foundation

public struct DataBlockHeader {
    /// Left-justified header text.
    public var left: String?
    /// Right-justified header text.
    public var right: String?

    public init(left: String? = nil, right: String? = nil) {
        self.left = left
        self.right = right
    }
}
