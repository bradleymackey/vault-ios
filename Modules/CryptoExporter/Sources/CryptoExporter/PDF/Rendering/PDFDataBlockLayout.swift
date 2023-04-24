import CoreGraphics
import Foundation

public protocol PDFDataBlockLayout {
    func rect(atIndex index: UInt) -> CGRect
    func isFullyWithinBounds(rect: CGRect) -> Bool
}
