import CoreGraphics
import CryptoExporter
import Foundation
import XCTest

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

    func test_rect_laysOutGridEvenly() {
        let sut = makeSUT(bounds: .square(90), tilesPerRow: 3)

        expectRow(
            for: sut,
            sizes: [.square(30), .square(30), .square(30)],
            origins: [.zero, CGPoint(x: 30, y: 0), CGPoint(x: 60, y: 0)]
        )
        expectColumn(
            for: sut,
            sizes: [.square(30), .square(30), .square(30)],
            origins: [.zero, CGPoint(x: 0, y: 30), CGPoint(x: 0, y: 60)]
        )
    }

    func test_rect_layoutSizesToRespectMargin() {
        let sut = makeSUT(bounds: .square(100), tilesPerRow: 3, margin: 5)

        expectRow(
            for: sut,
            sizes: [.square(30), .square(30), .square(30)],
            origins: [CGPoint(x: 5, y: 5), CGPoint(x: 35, y: 5), CGPoint(x: 65, y: 5)]
        )
        expectColumn(
            for: sut,
            sizes: [.square(30), .square(30), .square(30)],
            origins: [CGPoint(x: 5, y: 5), CGPoint(x: 5, y: 35), CGPoint(x: 5, y: 65)]
        )
    }

    func test_rect_escapesBoundsIfNegativeMargin() {
        let sut = makeSUT(bounds: .square(80), tilesPerRow: 3, margin: -5)

        expectRow(
            for: sut,
            sizes: [.square(30), .square(30), .square(30)],
            origins: [CGPoint(x: -5, y: -5), CGPoint(x: 25, y: -5), CGPoint(x: 55, y: -5)]
        )
        expectColumn(
            for: sut,
            sizes: [.square(30), .square(30), .square(30)],
            origins: [CGPoint(x: -5, y: -5), CGPoint(x: -5, y: 25), CGPoint(x: -5, y: 55)]
        )
    }

    func test_rect_layoutSizesToRespectSpacing() {
        let sut = makeSUT(bounds: .square(110), tilesPerRow: 3, spacing: 10)

        expectRow(
            for: sut,
            sizes: [.square(30), .square(30), .square(30)],
            origins: [.zero, CGPoint(x: 40, y: 0), CGPoint(x: 80, y: 0)]
        )
        expectColumn(
            for: sut,
            sizes: [.square(30), .square(30), .square(30)],
            origins: [.zero, CGPoint(x: 0, y: 40), CGPoint(x: 0, y: 80)]
        )
    }

    // MARK: - Helpers

    private func makeSUT(bounds: CGSize, tilesPerRow: UInt, margin: CGFloat = 0, spacing: CGFloat = 0) -> VerticalTilingDataBlockLayout {
        VerticalTilingDataBlockLayout(bounds: bounds, tilesPerRow: tilesPerRow, margin: margin, spacing: spacing)
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
