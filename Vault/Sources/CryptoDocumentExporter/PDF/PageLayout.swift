import CoreGraphics
import Foundation
import Spyable

/// Lays out content on a page.
@Spyable
public protocol PageLayout {
    /// Is the given rect within the given bounds of the page?
    func isFullyWithinBounds(rect: CGRect) -> Bool
}
