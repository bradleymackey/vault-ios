import UIKit

public struct DataBlockLabel {
    public var text: String
    public var font: UIFont
    public var textColor: UIColor
    public var padding: UIEdgeInsets

    public init(text: String, font: UIFont, textColor: UIColor = .black, padding: UIEdgeInsets) {
        self.text = text
        self.font = font
        self.textColor = textColor
        self.padding = padding
    }
}
