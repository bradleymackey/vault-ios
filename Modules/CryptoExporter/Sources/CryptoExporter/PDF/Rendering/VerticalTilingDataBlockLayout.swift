import CoreGraphics
import Foundation

/// Lays out square rects in a tile.
/// This is essentially an iterator that can be used once per layout.
public struct VerticalTilingDataBlockLayout: DataBlockLayout {
    public let bounds: CGSize
    public let tilesPerRow: UInt
    public let margin: CGFloat
    public let spacing: CGFloat

    public init(bounds: CGSize, tilesPerRow: UInt, margin: CGFloat = 0, spacing: CGFloat = 0) {
        self.bounds = bounds
        self.tilesPerRow = tilesPerRow
        self.margin = margin
        self.spacing = spacing
    }

    /// Gets the rect for this index.
    public func rect(atIndex index: UInt) -> CGRect {
        CGRect(
            origin: origin(index: index),
            size: CGSize(width: sideLength, height: sideLength)
        )
    }

    public func isFullyWithinBounds(rect: CGRect) -> Bool {
        let ourBounds = CGRect(origin: .zero, size: bounds)
        let effectiveBounds = ourBounds.insetBy(dx: margin, dy: margin)
        return effectiveBounds.intersection(rect).isAlmostEqual(to: rect)
    }

    /// Origin without any margin considerations
    private func origin(index: UInt) -> CGPoint {
        let rowNumber = index % tilesPerRow
        let columnNumber = index / tilesPerRow
        return CGPoint(
            x: applyOffset(position: rowNumber),
            y: applyOffset(position: columnNumber)
        )
    }

    private func applyOffset(position: UInt) -> CGFloat {
        let value = CGFloat(position)
        var position = value * sideLength
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
