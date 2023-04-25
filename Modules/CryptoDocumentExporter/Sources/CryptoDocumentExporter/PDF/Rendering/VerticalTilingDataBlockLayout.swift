import CoreGraphics
import Foundation

/// Lays out square rects in a tile.
/// This is essentially an iterator that can be used once per layout.
public struct VerticalTilingDataBlockLayout: PDFDataBlockLayout {
    public let bounds: CGRect
    public let tilesPerRow: UInt
    public let margin: CGFloat
    public let spacing: CGFloat

    public init(bounds: CGRect, tilesPerRow: UInt, margin: CGFloat = 0, spacing: CGFloat = 0) {
        self.bounds = bounds
        self.tilesPerRow = tilesPerRow
        self.margin = margin
        self.spacing = spacing
    }

    /// Gets the rect for this index.
    public func rect(atIndex index: UInt) -> CGRect? {
        let provisionalRect = CGRect(
            origin: origin(index: index),
            size: CGSize(width: sideLength, height: sideLength)
        )
        return isFullyWithinBounds(rect: provisionalRect) ? provisionalRect : nil
    }

    /// Determines if this rect fits within the bounds of the layout.
    public func isFullyWithinBounds(rect: CGRect) -> Bool {
        let effectiveBounds = bounds.insetBy(dx: margin, dy: margin)
        return effectiveBounds.intersection(rect).isAlmostEqual(to: rect)
    }

    private func origin(index: UInt) -> CGPoint {
        let rowNumber = index % tilesPerRow
        let columnNumber = index / tilesPerRow
        return CGPoint(
            x: applyOffset(position: rowNumber, offset: bounds.origin.x),
            y: applyOffset(position: columnNumber, offset: bounds.origin.y)
        )
    }

    private func applyOffset(position: UInt, offset: CGFloat) -> CGFloat {
        let value = CGFloat(position)
        var position = value * sideLength
        position += offset
        position += margin
        position += value * spacing
        return position
    }

    /// The length of the side of all tiles.
    private var sideLength: CGFloat {
        let horizontalSpacingRequired = CGFloat(tilesPerRow - 1) * spacing
        let totalHorizontalMargin = margin * 2
        let availableWidth = bounds.width - totalHorizontalMargin - horizontalSpacingRequired
        return availableWidth / CGFloat(tilesPerRow)
    }
}
