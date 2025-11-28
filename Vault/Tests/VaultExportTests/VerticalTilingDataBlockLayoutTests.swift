import CoreGraphics
import Foundation
import Testing
import VaultExport

struct VerticalTilingDataBlockLayoutTests {
    @Test
    func rect_isOriginForFirstPosition() {
        let sut = makeSUT(size: .square(90), tilesPerRow: 3)

        let first = sut.rect(atIndex: 0)

        #expect(first?.origin == .zero)
    }

    @Test
    func rect_isSizeOfSquareThatFits() {
        let sut = makeSUT(size: .square(90), tilesPerRow: 3)

        let first = sut.rect(atIndex: 0)

        #expect(first?.size == .square(30))
    }

    @Test
    func rect_laysOutGridEvenly() {
        let sut = makeSUT(size: .square(90), tilesPerRow: 3)

        expectFirstRow(
            for: sut,
            sizes: [.square(30), .square(30), .square(30)],
            origins: [.zero, CGPoint(x: 30, y: 0), CGPoint(x: 60, y: 0)],
        )
        expectFirstColumn(
            for: sut,
            sizes: [.square(30), .square(30), .square(30)],
            origins: [.zero, CGPoint(x: 0, y: 30), CGPoint(x: 0, y: 60)],
        )
    }

    @Test
    func rect_layoutSizesToRespectSpacing() {
        let sut = makeSUT(size: .square(110), tilesPerRow: 3, spacing: 10)

        expectFirstRow(
            for: sut,
            sizes: [.square(30), .square(30), .square(30)],
            origins: [.zero, CGPoint(x: 40, y: 0), CGPoint(x: 80, y: 0)],
        )
        expectFirstColumn(
            for: sut,
            sizes: [.square(30), .square(30), .square(30)],
            origins: [.zero, CGPoint(x: 0, y: 40), CGPoint(x: 0, y: 80)],
        )
    }

    @Test
    func rect_adjustsLayoutRelativeToBounds() {
        let sut = makeSUT(
            origin: .init(x: 20, y: 20),
            size: .square(100),
            tilesPerRow: 4,
        )

        expectFirstRow(
            for: sut,
            sizes: [.square(25), .square(25), .square(25), .square(25)],
            origins: [CGPoint(x: 20, y: 20), CGPoint(x: 45, y: 20), CGPoint(x: 70, y: 20), CGPoint(x: 95, y: 20)],
        )
        expectFirstColumn(
            for: sut,
            sizes: [.square(25), .square(25), .square(25), .square(25)],
            origins: [CGPoint(x: 20, y: 20), CGPoint(x: 20, y: 45), CGPoint(x: 20, y: 70), CGPoint(x: 20, y: 95)],
        )
    }

    @Test
    func rect_isNotNilIfContainedWithinBounds() {
        let sut = makeSUT(size: .square(100), tilesPerRow: 3)

        for index: UInt in 0 ..< 9 {
            #expect(sut.rect(atIndex: index) != nil)
        }
    }

    @Test
    func rect_isNilIfOutsideOfBounds() {
        let sut = makeSUT(size: .square(100), tilesPerRow: 3)

        for index: UInt in 9 ..< 100 {
            #expect(sut.rect(atIndex: index) == nil)
        }
    }

    @Test(arguments: [
        CGRect(x: 5, y: 5, width: 10, height: 10),
        CGRect(x: 5, y: 5, width: 90, height: 90),
        CGRect(x: 50, y: 50, width: 40, height: 40),
    ])
    func isFullyWithinBounds_containsItem(validRect: CGRect) {
        let sut = makeSUT(size: .square(100), tilesPerRow: 3)
        #expect(sut.isFullyWithinBounds(rect: validRect), "Does not contain \(validRect)")
    }

    @Test(arguments: [
        CGRect(x: -5, y: -5, width: 10, height: 10),
        CGRect(x: -5, y: -5, width: 500, height: 10),
    ])
    func isFullyWithinBounds_doesNotContainItem(invalidRect: CGRect) {
        let sut = makeSUT(size: .square(100), tilesPerRow: 3)
        #expect(!sut.isFullyWithinBounds(rect: invalidRect), "Contains \(invalidRect)")
    }

    // MARK: - Helpers

    private func makeSUT(
        origin: CGPoint = .zero,
        size: CGSize,
        tilesPerRow: UInt,
        spacing: CGFloat = 0,
    ) -> VerticalTilingDataBlockLayout {
        VerticalTilingDataBlockLayout(
            bounds: CGRect(origin: origin, size: size),
            tilesPerRow: tilesPerRow,
            spacing: spacing,
        )
    }

    private func expectFirstRow(
        for sut: VerticalTilingDataBlockLayout,
        sizes: [CGSize],
        origins: [CGPoint],
        sourceLocation: SourceLocation = #_sourceLocation,
    ) {
        let rowIndexes: [UInt] = Array(0 ..< sut.tilesPerRow)
        for (index, rowIndex) in rowIndexes.enumerated() {
            let point = sut.rect(atIndex: rowIndex)
            #expect(point?.size == sizes[index], "Unexpected size at index \(index)", sourceLocation: sourceLocation)
            #expect(
                point?.origin == origins[index],
                "Unexpected origin at index \(index)",
                sourceLocation: sourceLocation,
            )
        }
    }

    private func expectFirstColumn(
        for sut: VerticalTilingDataBlockLayout,
        sizes: [CGSize],
        origins: [CGPoint],
        sourceLocation: SourceLocation = #_sourceLocation,
    ) {
        let columnIndexes: [UInt] = Array(0 ..< sut.tilesPerRow).map { $0 * sut.tilesPerRow }
        for (index, columnIndex) in columnIndexes.enumerated() {
            let point = sut.rect(atIndex: columnIndex)
            #expect(point?.size == sizes[index], "Unexpected size at index \(index)", sourceLocation: sourceLocation)
            #expect(
                point?.origin == origins[index],
                "Unexpected origin at index \(index)",
                sourceLocation: sourceLocation,
            )
        }
    }
}

extension CGSize {
    fileprivate static func square(_ size: CGFloat) -> CGSize {
        CGSize(width: size, height: size)
    }
}
