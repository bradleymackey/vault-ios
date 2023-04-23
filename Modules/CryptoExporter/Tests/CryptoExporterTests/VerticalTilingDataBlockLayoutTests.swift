import CoreGraphics
import Foundation
import XCTest

/// Lays out square rects in a tile.
/// This is essentially an iterator that can be used once per layout.
struct VerticalTilingDataBlockLayout {
    let bounds: CGSize
    let tilesPerRow: UInt

    /// Gets the rect for this index.
    func rect(atIndex index: UInt) -> CGRect {
        CGRect(
            origin: origin(index: index),
            size: CGSize(width: sideLength, height: sideLength)
        )
    }

    private func origin(index: UInt) -> CGPoint {
        let rowNumber = index % tilesPerRow
        let columnNumber = index / tilesPerRow
        return CGPoint(
            x: CGFloat(rowNumber) * sideLength,
            y: CGFloat(columnNumber) * sideLength
        )
    }

    /// The length of the side of all tiles.
    private var sideLength: CGFloat {
        bounds.width / CGFloat(tilesPerRow)
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

        let first = sut.rect(atIndex: 0)
        XCTAssertEqual(first.size, .square(30))
        XCTAssertEqual(first.origin, .zero)

        let second = sut.rect(atIndex: 1)
        XCTAssertEqual(second.size, .square(30))
        XCTAssertEqual(second.origin, CGPoint(x: 30, y: 0))

        let third = sut.rect(atIndex: 2)
        XCTAssertEqual(third.size, .square(30))
        XCTAssertEqual(third.origin, CGPoint(x: 60, y: 0))
    }

    func test_rect_laysOutGridColumnEvenly() {
        let sut = makeSUT(bounds: .square(90), tilesPerRow: 3)

        let first = sut.rect(atIndex: 0)
        XCTAssertEqual(first.size, .square(30))
        XCTAssertEqual(first.origin, .zero)

        let second = sut.rect(atIndex: 3)
        XCTAssertEqual(second.size, .square(30))
        XCTAssertEqual(second.origin, CGPoint(x: 0, y: 30))

        let third = sut.rect(atIndex: 6)
        XCTAssertEqual(third.size, .square(30))
        XCTAssertEqual(third.origin, CGPoint(x: 0, y: 60))
    }

    // MARK: - Helpers

    private func makeSUT(bounds: CGSize, tilesPerRow: UInt) -> VerticalTilingDataBlockLayout {
        VerticalTilingDataBlockLayout(bounds: bounds, tilesPerRow: tilesPerRow)
    }
}

private extension CGSize {
    static func square(_ size: CGFloat) -> CGSize {
        CGSize(width: size, height: size)
    }
}
