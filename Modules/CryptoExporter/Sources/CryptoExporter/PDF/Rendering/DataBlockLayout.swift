import CoreGraphics
import Foundation

public protocol DataBlockLayout {
    func rect(atIndex index: UInt) -> CGRect
    func isFullyWithinBounds(rect: CGRect) -> Bool
}
