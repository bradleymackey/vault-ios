import CoreGraphics
import Foundation
import VaultExport
import XCTest

final class VerticalTilingDataBlockLayoutTests: XCTestCase {
    func test_rect_isOriginForFirstPosition() {
        let sut = makeSUT(size: .square(90), tilesPerRow: 3)

        let first = sut.rect(atIndex: 0)

        XCTAssertEqual(first?.origin, .zero)
    }

    func test_rect_isSizeOfSquareThatFits() {
        let sut = makeSUT(size: .square(90), tilesPerRow: 3)

        let first = sut.rect(atIndex: 0)

        XCTAssertEqual(first?.size, .square(30))
    }

    func test_rect_laysOutGridEvenly() {
        let sut = makeSUT(size: .square(90), tilesPerRow: 3)

        expectFirstRow(
            for: sut,
            sizes: [.square(30), .square(30), .square(30)],
            origins: [.zero, CGPoint(x: 30, y: 0), CGPoint(x: 60, y: 0)]
        )
        expectFirstColumn(
            for: sut,
            sizes: [.square(30), .square(30), .square(30)],
            origins: [.zero, CGPoint(x: 0, y: 30), CGPoint(x: 0, y: 60)]
        )
    }

    func test_rect_layoutSizesToRespectSpacing() {
        let sut = makeSUT(size: .square(110), tilesPerRow: 3, spacing: 10)

        expectFirstRow(
            for: sut,
            sizes: [.square(30), .square(30), .square(30)],
            origins: [.zero, CGPoint(x: 40, y: 0), CGPoint(x: 80, y: 0)]
        )
        expectFirstColumn(
            for: sut,
            sizes: [.square(30), .square(30), .square(30)],
            origins: [.zero, CGPoint(x: 0, y: 40), CGPoint(x: 0, y: 80)]
        )
    }

    func test_rect_adjustsLayoutRelativeToBounds() {
        let sut = makeSUT(
            origin: .init(x: 20, y: 20),
            size: .square(100),
            tilesPerRow: 4
        )

        expectFirstRow(
            for: sut,
            sizes: [.square(25), .square(25), .square(25), .square(25)],
            origins: [CGPoint(x: 20, y: 20), CGPoint(x: 45, y: 20), CGPoint(x: 70, y: 20), CGPoint(x: 95, y: 20)]
        )
        expectFirstColumn(
            for: sut,
            sizes: [.square(25), .square(25), .square(25), .square(25)],
            origins: [CGPoint(x: 20, y: 20), CGPoint(x: 20, y: 45), CGPoint(x: 20, y: 70), CGPoint(x: 20, y: 95)]
        )
    }

    func test_rect_isNotNilIfContainedWithinBounds() {
        let sut = makeSUT(size: .square(100), tilesPerRow: 3)

        for index: UInt in 0 ..< 9 {
            XCTAssertNotNil(sut.rect(atIndex: index))
        }
    }

    func test_rect_isNilIfOutsideOfBounds() {
        let sut = makeSUT(size: .square(100), tilesPerRow: 3)

        for index: UInt in 9 ..< 100 {
            XCTAssertNil(sut.rect(atIndex: index))
        }
    }

    func test_isFullyWithinBounds_containsItem() {
        let sut = makeSUT(size: .square(100), tilesPerRow: 3)

        let validRects: [CGRect] = [
            CGRect(x: 5, y: 5, width: 10, height: 10),
            CGRect(x: 5, y: 5, width: 90, height: 90),
            CGRect(x: 50, y: 50, width: 40, height: 40),
        ]

        for rect in validRects {
            XCTAssertTrue(sut.isFullyWithinBounds(rect: rect), "Does not contain \(rect)")
        }
    }

    func test_isFullyWithinBounds_doesNotContainItem() {
        let sut = makeSUT(size: .square(100), tilesPerRow: 3)

        let invalidRects: [CGRect] = [
            CGRect(x: -5, y: -5, width: 10, height: 10),
            CGRect(x: -5, y: -5, width: 500, height: 10),
        ]

        for rect in invalidRects {
            XCTAssertFalse(sut.isFullyWithinBounds(rect: rect), "Contains \(rect)")
        }
    }

    // MARK: - Helpers

    private func makeSUT(
        origin: CGPoint = .zero,
        size: CGSize,
        tilesPerRow: UInt,
        spacing: CGFloat = 0
    ) -> VerticalTilingDataBlockLayout {
        VerticalTilingDataBlockLayout(
            bounds: CGRect(origin: origin, size: size),
            tilesPerRow: tilesPerRow,
            spacing: spacing
        )
    }

    private func expectFirstRow(for sut: VerticalTilingDataBlockLayout, sizes: [CGSize], origins: [CGPoint]) {
        let rowIndexes: [UInt] = Array(0 ..< sut.tilesPerRow)
        for (index, rowIndex) in rowIndexes.enumerated() {
            let point = sut.rect(atIndex: rowIndex)
            XCTAssertEqual(point?.size, sizes[index])
            XCTAssertEqual(point?.origin, origins[index])
        }
    }

    private func expectFirstColumn(for sut: VerticalTilingDataBlockLayout, sizes: [CGSize], origins: [CGPoint]) {
        let columnIndexes: [UInt] = Array(0 ..< sut.tilesPerRow).map { $0 * sut.tilesPerRow }
        for (index, columnIndex) in columnIndexes.enumerated() {
            let point = sut.rect(atIndex: columnIndex)
            XCTAssertEqual(point?.size, sizes[index])
            XCTAssertEqual(point?.origin, origins[index])
        }
    }
}

extension CGSize {
    fileprivate static func square(_ size: CGFloat) -> CGSize {
        CGSize(width: size, height: size)
    }
}
