import CoreGraphics
import Foundation
import XCTest

/// Lays out square rects in a tile.
/// This is essentially an iterator that can be used once per layout.
struct VerticalTilingDataBlockLayout {
    let bounds: CGSize
    let tilesPerRow: UInt
    let margin: CGFloat

    init(bounds: CGSize, tilesPerRow: UInt, margin: CGFloat = 0) {
        self.bounds = bounds
        self.tilesPerRow = tilesPerRow
        self.margin = margin
    }

    /// Gets the rect for this index.
    func rect(atIndex index: UInt) -> CGRect {
        CGRect(
            origin: origin(index: index),
            size: CGSize(width: sideLength, height: sideLength)
        )
    }

    private func origin(index: UInt) -> CGPoint {
        var point = originalOrigin(index: index)
        point.x += margin
        point.y += margin
        return point
    }

    /// Origin without any margin considerations
    private func originalOrigin(index: UInt) -> CGPoint {
        let rowNumber = index % tilesPerRow
        let columnNumber = index / tilesPerRow
        return CGPoint(
            x: CGFloat(rowNumber) * sideLength,
            y: CGFloat(columnNumber) * sideLength
        )
    }

    /// The length of the side of all tiles.
    private var sideLength: CGFloat {
        let totalHorizontalMargin = margin * 2
        let availableWidth = bounds.width - totalHorizontalMargin
        return availableWidth / CGFloat(tilesPerRow)
    }
}

final class VerticalTilingDataBlockLayoutTests: XCTestCase {
    func test_rect_isOriginForFirstPosition() {
        let sut = makeSUT(bounds: .square(90), tilesPerRow: 3)

        let first = sut.rect(atIndex: 0)

        XCTAssertEqual(first.origin, .zero)
    }

    func test_rect_isSizeOfSquareThatFits() {
        let sut = makeSUT(bounds: .square(90), tilesPerRow: 3)

        let first = sut.rect(atIndex: 0)

        XCTAssertEqual(first.size, .square(30))
    }

    func test_rect_laysOutGridRowEvenly() {
        let sut = makeSUT(bounds: .square(90), tilesPerRow: 3)

        expectRow(
            for: sut,
            sizes: [.square(30), .square(30), .square(30)],
            origins: [.zero, CGPoint(x: 30, y: 0), CGPoint(x: 60, y: 0)]
        )
    }

    func test_rect_laysOutGridColumnEvenly() {
        let sut = makeSUT(bounds: .square(90), tilesPerRow: 3)

        expectColumn(
            for: sut,
            sizes: [.square(30), .square(30), .square(30)],
            origins: [.zero, CGPoint(x: 0, y: 30), CGPoint(x: 0, y: 60)]
        )
    }

    func test_rectWithMargin_layoutRowSizesToRespectMargin() {
        let sut = makeSUT(bounds: .square(100), tilesPerRow: 3, margin: 5)

        expectRow(
            for: sut,
            sizes: [.square(30), .square(30), .square(30)],
            origins: [CGPoint(x: 5, y: 5), CGPoint(x: 35, y: 5), CGPoint(x: 65, y: 5)]
        )
    }

    func test_rectWithMargin_layoutColumnSizesToRespectMargin() {
        let sut = makeSUT(bounds: .square(100), tilesPerRow: 3, margin: 5)

        expectColumn(
            for: sut,
            sizes: [.square(30), .square(30), .square(30)],
            origins: [CGPoint(x: 5, y: 5), CGPoint(x: 5, y: 35), CGPoint(x: 5, y: 65)]
        )
    }

    // MARK: - Helpers

    private func makeSUT(bounds: CGSize, tilesPerRow: UInt, margin: CGFloat = 0) -> VerticalTilingDataBlockLayout {
        VerticalTilingDataBlockLayout(bounds: bounds, tilesPerRow: tilesPerRow, margin: margin)
    }

    private func expectRow(for sut: VerticalTilingDataBlockLayout, sizes: [CGSize], origins: [CGPoint]) {
        let rowIndexes: [UInt] = Array(0 ..< sut.tilesPerRow)
        for (index, rowIndex) in rowIndexes.enumerated() {
            let point = sut.rect(atIndex: rowIndex)
            XCTAssertEqual(point.size, sizes[index])
            XCTAssertEqual(point.origin, origins[index])
        }
    }

    private func expectColumn(for sut: VerticalTilingDataBlockLayout, sizes: [CGSize], origins: [CGPoint]) {
        let columnIndexes: [UInt] = [0, sut.tilesPerRow, sut.tilesPerRow * 2]
        for (index, columnIndex) in columnIndexes.enumerated() {
            let point = sut.rect(atIndex: columnIndex)
            XCTAssertEqual(point.size, sizes[index])
            XCTAssertEqual(point.origin, origins[index])
        }
    }
}

private extension CGSize {
    static func square(_ size: CGFloat) -> CGSize {
        CGSize(width: size, height: size)
    }
}
