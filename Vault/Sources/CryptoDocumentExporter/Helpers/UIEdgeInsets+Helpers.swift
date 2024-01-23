import UIKit

extension UIEdgeInsets {
    public var verticalTotal: CGFloat {
        top + bottom
    }

    public var horizontalTotal: CGFloat {
        left + right
    }

    public init(uniform: CGFloat) {
        self = .init(top: uniform, left: uniform, bottom: uniform, right: uniform)
    }
}
