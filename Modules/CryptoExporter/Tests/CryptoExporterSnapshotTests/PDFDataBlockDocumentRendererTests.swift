import CryptoExporter
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
        let document = DataBlockExportDocument(dataBlockImageData: [anyData()])
        let pdf = try XCTUnwrap(sut.render(document: document))

        assertSnapshot(matching: pdf, as: .pdf())
    }

    func test_render_drawsRowOfImages() throws {
        let sut = makeSUT(tilesPerRow: 3)
        let document = DataBlockExportDocument(dataBlockImageData: Array(repeating: anyData(), count: 3))
        let pdf = try XCTUnwrap(sut.render(document: document))

        assertSnapshot(matching: pdf, as: .pdf())
    }

    func test_render_drawsGridRowOfImagesWith10TilesPerRow() throws {
        let sut = makeSUT(tilesPerRow: 10)
        let document = DataBlockExportDocument(dataBlockImageData: Array(repeating: anyData(), count: 24))
        let pdf = try XCTUnwrap(sut.render(document: document))

        assertSnapshot(matching: pdf, as: .pdf())
    }

    func test_render_drawsMultiplePagesOfImages() throws {
        let sut = makeSUT(tilesPerRow: 3)
        let document = DataBlockExportDocument(dataBlockImageData: Array(repeating: anyData(), count: 14))
        let pdf = try XCTUnwrap(sut.render(document: document))

        assertSnapshot(matching: pdf, as: .pdf(page: 1), named: "page1")
        assertSnapshot(matching: pdf, as: .pdf(page: 2), named: "page2")
    }

    func test_render_ignoresOffsetForTitleOnSecondPage() throws {
        let sut = makeSUT(tilesPerRow: 3)
        let titleLabel = DataBlockLabel(
            text: "Hello World",
            font: UIFont.systemFont(ofSize: 50, weight: .bold),
            padding: (top: 36, bottom: 22)
        )
        let document = DataBlockExportDocument(
            title: titleLabel,
            dataBlockImageData: Array(repeating: anyData(), count: 14)
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
            padding: (top: 36, bottom: 22)
        )
        let document = DataBlockExportDocument(
            title: titleLabel,
            dataBlockImageData: Array(repeating: anyData(), count: 14)
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
            padding: (top: 36, bottom: 22)
        )
        let document = DataBlockExportDocument(
            title: titleLabel,
            dataBlockImageData: Array(repeating: anyData(), count: 14)
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
            padding: (top: 36, bottom: 22)
        )
        let document = DataBlockExportDocument(
            subtitle: titleLabel,
            dataBlockImageData: Array(repeating: anyData(), count: 14)
        )
        let pdf = try XCTUnwrap(sut.render(document: document))

        assertSnapshot(matching: pdf, as: .pdf())
    }

    func test_render_drawsTitleAndSubtitleAboveImages() throws {
        let sut = makeSUT(tilesPerRow: 10)
        let titleLabel = DataBlockLabel(
            text: "Hello World",
            font: UIFont.systemFont(ofSize: 50, weight: .bold),
            padding: (top: 36, bottom: 0)
        )
        let subtitleMain = Array(repeating: "Subtitle", count: 50).joined(separator: " ")
        let subtitleLabel = DataBlockLabel(
            text: "<START> \(subtitleMain) <END>",
            font: UIFont.systemFont(ofSize: 14, weight: .regular),
            padding: (top: 12, bottom: 14)
        )
        let document = DataBlockExportDocument(
            title: titleLabel,
            subtitle: subtitleLabel,
            dataBlockImageData: Array(repeating: anyData(), count: 14)
        )
        let pdf = try XCTUnwrap(sut.render(document: document))

        assertSnapshot(matching: pdf, as: .pdf())
    }

    // MARK: - Helpers

    private func makeSUT(
        tilesPerRow: UInt,
        imageRenderer: RGBCyclingStubColorImageRenderer = RGBCyclingStubColorImageRenderer()
    ) -> some PDFDocumentRenderer<DataBlockExportDocument> {
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

    private func emptyDocument() -> DataBlockExportDocument {
        DataBlockExportDocument(dataBlockImageData: [])
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
