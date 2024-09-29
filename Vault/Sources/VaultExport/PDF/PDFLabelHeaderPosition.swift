import Foundation
import UIKit

/// The position that a header label can be rendered in.
enum PDFLabelHeaderPosition {
    case left, right

    var textAlignment: NSTextAlignment {
        switch self {
        case .left: .left
        case .right: .right
        }
    }

    var lineBreakMode: NSLineBreakMode {
        switch self {
        case .left: .byTruncatingTail
        case .right: .byTruncatingHead
        }
    }

    func xPosition(width: CGFloat, margins: UIEdgeInsets) -> CGFloat {
        switch self {
        case .left: margins.left
        case .right: width + margins.left
        }
    }
}
