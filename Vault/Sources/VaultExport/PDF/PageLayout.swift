import CoreGraphics
import Foundation

/// Lays out content on a page.
/// @mockable
public protocol PageLayout {
    /// Is the given rect within the given bounds of the page?
    func isFullyWithinBounds(rect: CGRect) -> Bool
}
