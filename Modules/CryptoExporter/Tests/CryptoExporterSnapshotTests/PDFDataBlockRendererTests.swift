import CryptoExporter
import Foundation
import PDFKit
import SnapshotTesting
import XCTest

struct DataBlockLabel {
    var text: String
    var font: UIFont
    var padding: (top: CGFloat, bottom: CGFloat)
}

struct DataBlockExportDocument {
    var title: DataBlockLabel?
    var subtitle: DataBlockLabel?
    var dataBlockImageData: [Data]
}

protocol PDFDocumentRenderer<Document> {
    associatedtype Document
    func render(document: Document) -> PDFDocument?
}

protocol PDFImageRenderer {
    func makeImage(fromData data: Data) -> UIImage?
}

class PDFDataBlockRenderer<
    RendererFactory: PDFRendererFactory,
    ImageRenderer: PDFImageRenderer,
    BlockLayout: DataBlockLayout
>: PDFDocumentRenderer {
    typealias Document = DataBlockExportDocument

    let rendererFactory: RendererFactory
    let imageRenderer: ImageRenderer
    let blockLayout: (CGRect) -> BlockLayout

    init(
        rendererFactory: RendererFactory,
        imageRenderer: ImageRenderer,
        blockLayout: @escaping (CGRect) -> BlockLayout
    ) {
        self.rendererFactory = rendererFactory
        self.imageRenderer = imageRenderer
        self.blockLayout = blockLayout
    }

    func render(document: DataBlockExportDocument) -> PDFDocument? {
        let renderer = rendererFactory.makeRenderer()
        let data = renderer.pdfData { context in
            let pageRect = context.pdfContextBounds

            context.beginPage()

            var currentVerticalOffset = 0.0
            for label in [document.title, document.subtitle] {
                guard let label else { continue }
                let (attributedString, rect) = renderedLabel(for: label, pageRect: pageRect, textTop: currentVerticalOffset, horizontalPadding: 10)
                attributedString.draw(in: rect)
                currentVerticalOffset += label.padding.top
                currentVerticalOffset += rect.height
            }

            let imageResizer = UIImageResizer(mode: .noSmoothing)
            var blockLayoutEngine = blockLayout(
                pageRect.inset(by: UIEdgeInsets(top: currentVerticalOffset, left: 0, bottom: 0, right: 0))
            )

            var imageNumberForPage = 0

            for imageData in document.dataBlockImageData {
                defer { imageNumberForPage += 1 }
                guard let image = imageRenderer.makeImage(fromData: imageData) else {
                    continue
                }

                var desiredRect = blockLayoutEngine.rect(atIndex: UInt(imageNumberForPage))
                if !blockLayoutEngine.isFullyWithinBounds(rect: desiredRect) {
                    context.beginPage()
                    blockLayoutEngine = blockLayout(
                        pageRect.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
                    )
                    imageNumberForPage = 0
                    desiredRect = blockLayoutEngine.rect(atIndex: UInt(imageNumberForPage))
                }

                let resized = imageResizer.resize(image: image, to: desiredRect.size)
                resized.draw(in: desiredRect)
            }
        }
        return PDFDocument(data: data)
    }

    private func renderedLabel(for label: DataBlockLabel, pageRect: CGRect, textTop: CGFloat, horizontalPadding: CGFloat) -> (NSAttributedString, CGRect) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping

        let attributedText = NSAttributedString(
            string: label.text,
            attributes: [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.font: label.font,
            ]
        )
        let width = pageRect.width - horizontalPadding * 2
        let boundingRect = attributedText.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            context: nil
        )
        let textRect = CGRect(
            x: horizontalPadding,
            y: textTop + label.padding.top,
            width: width,
            height: boundingRect.height + label.padding.bottom
        )
        return (attributedText, textRect)
    }
}

final class PDFDataBlockRendererTests: XCTestCase {
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
        PDFDataBlockRenderer(
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
    func makeImage(fromData _: Data) -> UIImage? {
        defer { currentState += 1 }
        return UIImage.from(color: states[currentState % states.count])
    }
}
