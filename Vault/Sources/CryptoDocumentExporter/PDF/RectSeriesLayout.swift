import CoreGraphics
import Foundation
import Spyable

/// Lays out a series of rects known by an index position.
///
/// The layout is able to provide positions on a canvas for each rect to be laid out, identified
/// by the index number of the rect.
@Spyable
public protocol RectSeriesLayout {
    /// - Returns: `nil` if we cannot fit a block on this page at this position.
    func rect(atIndex index: UInt) -> CGRect?
    /// - Returns: the consistent spacing used between the drawn rects
    var spacing: CGFloat { get }
}
