import CryptoDocumentExporter
import Foundation
import PDFKit
import SnapshotTesting
import XCTest

final class PDFDataBlockDocumentRendererTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    func test_render_drawsEmptyPDFDocument() throws {
        let sut = makeSUT(tilesPerRow: 3)
        let pdf = try XCTUnwrap(sut.render(document: emptyDocument()))

        assertSnapshot(matching: pdf, as: .pdf())
    }

    func test_render_drawsSingleImage() throws {
        let sut = makeSUT(tilesPerRow: 3)
        let document = DataBlockDocument(content: [.images([anyData()])])
        let pdf = try XCTUnwrap(sut.render(document: document))

        assertSnapshot(matching: pdf, as: .pdf())
    }

    func test_render_drawsRowOfImages() throws {
        let sut = makeSUT(tilesPerRow: 3)
        let document = DataBlockDocument(content: [.images(Array(repeating: anyData(), count: 3))])
        let pdf = try XCTUnwrap(sut.render(document: document))

        assertSnapshot(matching: pdf, as: .pdf())
    }

    func test_render_drawsIntersposedImagesAndTitles() throws {
        let sut = makeSUT(tilesPerRow: 10)
        let document = DataBlockDocument(content: [
            .images(Array(repeating: anyData(), count: 10)),
            .title(longSubtitle(padding: .zero)),
            .images(Array(repeating: anyData(), count: 3)),
            .title(longSubtitle(padding: .zero)),
            .images(Array(repeating: anyData(), count: 2)),
            .title(longSubtitle(padding: .zero)),
        ])
        let pdf = try XCTUnwrap(sut.render(document: document))

        assertSnapshot(matching: pdf, as: .pdf())
    }

    func test_render_drawsGridRowOfImagesWith10TilesPerRow() throws {
        let sut = makeSUT(tilesPerRow: 10)
        let document = DataBlockDocument(content: [.images(Array(repeating: anyData(), count: 24))])
        let pdf = try XCTUnwrap(sut.render(document: document))

        assertSnapshot(matching: pdf, as: .pdf())
    }

    func test_render_drawsMultiplePagesOfImages() throws {
        let sut = makeSUT(tilesPerRow: 3)
        let document = DataBlockDocument(content: [.images(Array(repeating: anyData(), count: 14))])
        let pdf = try XCTUnwrap(sut.render(document: document))

        assertSnapshot(matching: pdf, as: .pdf(page: 1), named: "page1")
        assertSnapshot(matching: pdf, as: .pdf(page: 2), named: "page2")
    }

    func test_render_ignoresOffsetForTitleOnSecondPage() throws {
        let sut = makeSUT(tilesPerRow: 3)
        let titleLabel = DataBlockLabel(
            text: "Hello World",
            font: UIFont.systemFont(ofSize: 50, weight: .bold),
            padding: .init(top: 36, left: 10, bottom: 22, right: 10)
        )
        let document = DataBlockDocument(
            content: [
                .title(titleLabel),
                .images(Array(repeating: anyData(), count: 14)),
            ]
        )
        let pdf = try XCTUnwrap(sut.render(document: document))

        assertSnapshot(matching: pdf, as: .pdf(page: 1), named: "page1")
        assertSnapshot(matching: pdf, as: .pdf(page: 2), named: "page2")
    }

    func test_render_drawsTitleAboveImages() throws {
        let sut = makeSUT(tilesPerRow: 10)
        let titleLabel = DataBlockLabel(
            text: "Hello World",
            font: UIFont.systemFont(ofSize: 50, weight: .bold),
            padding: .init(top: 36, left: 10, bottom: 22, right: 10)
        )
        let document = DataBlockDocument(
            content: [
                .title(titleLabel),
                .images(Array(repeating: anyData(), count: 14)),
            ]
        )
        let pdf = try XCTUnwrap(sut.render(document: document))

        assertSnapshot(matching: pdf, as: .pdf())
    }

    func test_render_drawsLongTitleAboveImages() throws {
        let sut = makeSUT(tilesPerRow: 10)
        let title = Array(repeating: "Title", count: 10).joined(separator: " ")
        let titleLabel = DataBlockLabel(
            text: "<START> \(title) <END>",
            font: UIFont.systemFont(ofSize: 50, weight: .bold),
            padding: .init(top: 36, left: 10, bottom: 22, right: 10)
        )
        let document = DataBlockDocument(
            content: [
                .title(titleLabel),
                .images(Array(repeating: anyData(), count: 14)),
            ]
        )
        let pdf = try XCTUnwrap(sut.render(document: document))

        assertSnapshot(matching: pdf, as: .pdf())
    }

    func test_render_drawsSubtitleAboveImages() throws {
        let sut = makeSUT(tilesPerRow: 10)
        let subtitleMain = Array(repeating: "Subtitle", count: 50).joined(separator: " ")
        let titleLabel = DataBlockLabel(
            text: "<START> \(subtitleMain) <END>",
            font: UIFont.systemFont(ofSize: 14, weight: .regular),
            padding: .init(top: 36, left: 10, bottom: 22, right: 10)
        )
        let document = DataBlockDocument(
            content: [
                .title(titleLabel),
                .images(Array(repeating: anyData(), count: 14)),
            ]
        )
        let pdf = try XCTUnwrap(sut.render(document: document))

        assertSnapshot(matching: pdf, as: .pdf())
    }

    func test_render_drawsTitleAndSubtitleAboveImages() throws {
        let sut = makeSUT(tilesPerRow: 10)
        let titleLabel = DataBlockLabel(
            text: "Hello World",
            font: UIFont.systemFont(ofSize: 50, weight: .bold),
            padding: .init(top: 36, left: 10, bottom: 0, right: 10)
        )
        let document = DataBlockDocument(
            content: [
                .title(titleLabel),
                .title(longSubtitle()),
                .images(Array(repeating: anyData(), count: 14)),
            ]
        )
        let pdf = try XCTUnwrap(sut.render(document: document))

        assertSnapshot(matching: pdf, as: .pdf())
    }

    func test_render_labelsRespectPadding() throws {
        let sut = makeSUT(tilesPerRow: 10)
        let title = longTitle(padding: .init(top: 40, left: 40, bottom: 10, right: 40))
        let subtitle = longSubtitle(padding: .init(top: 40, left: 60, bottom: 10, right: 60))
        let document = DataBlockDocument(
            content: [
                .title(title),
                .title(subtitle),
                .images(Array(repeating: anyData(), count: 0)),
            ]
        )
        let pdf = try XCTUnwrap(sut.render(document: document))

        assertSnapshot(matching: pdf, as: .pdf())
    }

    func test_render_drawsShortHeaders() throws {
        let pdf = try makeDocumentWithHeaderGenerator(headerGenerator: ShortHeaderGenerator())

        assertSnapshot(matching: pdf, as: .pdf())
    }

    func test_render_drawsLongHeaders() throws {
        let pdf = try makeDocumentWithHeaderGenerator(headerGenerator: LongHeaderGenerator())

        assertSnapshot(matching: pdf, as: .pdf())
    }

    func test_render_drawsLeftHeadersOnly() throws {
        let pdf = try makeDocumentWithHeaderGenerator(headerGenerator: LeftHeaderGenerator())

        assertSnapshot(matching: pdf, as: .pdf())
    }

    func test_render_drawsRightHeadersOnly() throws {
        let pdf = try makeDocumentWithHeaderGenerator(headerGenerator: RightHeaderGenerator())

        assertSnapshot(matching: pdf, as: .pdf())
    }

    func test_render_drawsHeadersOnAllPages() throws {
        let pdf = try makeDocumentWithHeaderGenerator(headerGenerator: PageNumberHeaderGenerator(), numberOfImages: 50)

        assertSnapshot(matching: pdf, as: .pdf(page: 1))
        assertSnapshot(matching: pdf, as: .pdf(page: 2))
    }

    // MARK: - Helpers

    private func makeSUT(
        tilesPerRow: UInt,
        imageRenderer: RGBCyclingStubColorImageRenderer = RGBCyclingStubColorImageRenderer()
    ) -> some PDFDocumentRenderer<DataBlockDocument> {
        PDFDataBlockDocumentRenderer(
            rendererFactory: StubPDFRendererFactory(),
            imageRenderer: imageRenderer,
            blockLayout: { size in
                VerticalTilingDataBlockLayout(bounds: size, tilesPerRow: tilesPerRow, margin: 10, spacing: 5)
            }
        )
    }

    private func anyData() -> Data {
        Data(repeating: 0xFF, count: 10)
    }

    private func emptyDocument() -> DataBlockDocument {
        DataBlockDocument(content: [])
    }

    private func longTitle(padding: UIEdgeInsets = .init(top: 36, left: 10, bottom: 0, right: 10)) -> DataBlockLabel {
        let title = Array(repeating: "Title", count: 10).joined(separator: " ")
        return DataBlockLabel(
            text: "<START> \(title) <END>",
            font: UIFont.systemFont(ofSize: 50, weight: .bold),
            padding: padding
        )
    }

    private func longSubtitle(padding: UIEdgeInsets = .init(top: 12, left: 10, bottom: 14, right: 10))
        -> DataBlockLabel
    {
        let subtitleMain = Array(repeating: "Subtitle", count: 50).joined(separator: " ")
        return DataBlockLabel(
            text: "<START> \(subtitleMain) <END>",
            font: UIFont.systemFont(ofSize: 14, weight: .regular),
            padding: padding
        )
    }

    private func makeDocumentWithHeaderGenerator(
        headerGenerator: any DataBlockHeaderGenerator,
        numberOfImages: Int = 10
    ) throws -> PDFDocument {
        let sut = PDFDataBlockDocumentRenderer(
            rendererFactory: StubPDFRendererFactory(),
            imageRenderer: PlainBlackColorImageRenderer(),
            blockLayout: { size in
                VerticalTilingDataBlockLayout(bounds: size, tilesPerRow: 5, margin: 10, spacing: 5)
            }
        )
        let title = DataBlockLabel(
            text: "My Title",
            font: UIFont.systemFont(ofSize: 50, weight: .bold),
            padding: .zero
        )
        let subtitle = DataBlockLabel(
            text: "Testing headers only - no padding on these labels",
            font: UIFont.systemFont(ofSize: 18, weight: .regular),
            padding: .zero
        )
        let document = DataBlockDocument(
            headerGenerator: headerGenerator,
            content: [
                .title(title),
                .title(subtitle),
                .images(Array(repeating: anyData(), count: numberOfImages)),
            ]
        )
        return try XCTUnwrap(sut.render(document: document))
    }
}

private struct StubPDFRendererFactory: PDFRendererFactory {
    // us letter size for stub
    var size = CGSize(width: 8.5 * 72, height: 11 * 72)
    var rect: CGRect {
        CGRect(origin: .zero, size: size)
    }

    func makeRenderer() -> UIGraphicsPDFRenderer {
        UIGraphicsPDFRenderer(bounds: rect)
    }
}

private class RGBCyclingStubColorImageRenderer: PDFImageRenderer {
    var states: [UIColor] = [.red, .green, .blue]
    var currentState = 0
    func makeImage(fromData _: Data, size: CGSize) -> UIImage? {
        defer { currentState += 1 }
        let image = UIImage.from(color: states[currentState % states.count])
        let resizer = UIImageResizer(mode: .noSmoothing)
        return resizer.resize(image: image, to: size)
    }
}

private class PlainBlackColorImageRenderer: PDFImageRenderer {
    func makeImage(fromData _: Data, size _: CGSize) -> UIImage? {
        UIImage.from(color: .black)
    }
}

private class ShortHeaderGenerator: DataBlockHeaderGenerator {
    func makeHeader(pageNumber _: Int) -> DataBlockHeader? {
        DataBlockHeader(left: "LEFT", right: "RIGHT")
    }
}

private class LongHeaderGenerator: DataBlockHeaderGenerator {
    func makeHeader(pageNumber _: Int) -> DataBlockHeader? {
        let left = Array(repeating: "LEFT", count: 100).joined(separator: " ")
        let right = Array(repeating: "RIGHT", count: 100).joined(separator: " ")
        return DataBlockHeader(left: left, right: right)
    }
}

private class LeftHeaderGenerator: DataBlockHeaderGenerator {
    func makeHeader(pageNumber _: Int) -> DataBlockHeader? {
        let left = Array(repeating: "LEFT", count: 100).joined(separator: " ")
        return DataBlockHeader(left: left, right: nil)
    }
}

private class RightHeaderGenerator: DataBlockHeaderGenerator {
    func makeHeader(pageNumber _: Int) -> DataBlockHeader? {
        let right = Array(repeating: "RIGHT", count: 100).joined(separator: " ")
        return DataBlockHeader(left: nil, right: right)
    }
}

private class PageNumberHeaderGenerator: DataBlockHeaderGenerator {
    func makeHeader(pageNumber: Int) -> DataBlockHeader? {
        DataBlockHeader(left: "L: Page \(pageNumber)", right: "R: Page \(pageNumber)")
    }
}
