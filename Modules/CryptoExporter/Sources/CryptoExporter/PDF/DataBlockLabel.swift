import UIKit

public struct DataBlockLabel {
    public var text: String
    public var font: UIFont
    public var padding: (top: CGFloat, bottom: CGFloat)

    public init(text: String, font: UIFont, padding: (top: CGFloat, bottom: CGFloat)) {
        self.text = text
        self.font = font
        self.padding = padding
    }
}
