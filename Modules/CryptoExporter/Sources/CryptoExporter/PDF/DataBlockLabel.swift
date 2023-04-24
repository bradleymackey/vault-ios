import UIKit

public struct DataBlockLabel {
    public var text: String
    public var font: UIFont
    public var padding: UIEdgeInsets

    public init(text: String, font: UIFont, padding: UIEdgeInsets) {
        self.text = text
        self.font = font
        self.padding = padding
    }
}
