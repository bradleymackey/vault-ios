import CoreGraphics
import Foundation
import Spyable

@Spyable
public protocol PDFDataBlockLayout {
    /// - Returns: `nil` if we cannot fit a block on this page at this position.
    func rect(atIndex index: UInt) -> CGRect?
}
