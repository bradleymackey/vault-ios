import UIKit

extension UIEdgeInsets {
    var verticalTotal: CGFloat {
        top + bottom
    }

    var horizontalTotal: CGFloat {
        left + right
    }

    init(uniform: CGFloat) {
        self = .init(top: uniform, left: uniform, bottom: uniform, right: uniform)
    }
}
