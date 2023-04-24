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

            var offsetForTitle = 0.0
            if let title = document.title {
                let (titleString, titleRect) = titleLabel(for: title, pageRect: pageRect)
                titleString.draw(in: titleRect)
                offsetForTitle += title.padding.top
                offsetForTitle += titleRect.height
            }

            let imageResizer = UIImageResizer(mode: .noSmoothing)
            let inset = UIEdgeInsets(top: offsetForTitle, left: 0, bottom: 0, right: 0)
            let blockLayoutEngine = blockLayout(pageRect.inset(by: inset))

            var imageNumberForPage = 0

            for imageData in document.dataBlockImageData {
                defer { imageNumberForPage += 1 }
                guard let image = imageRenderer.makeImage(fromData: imageData) else {
                    continue
                }

                var desiredRect = blockLayoutEngine.rect(atIndex: UInt(imageNumberForPage))
                if !blockLayoutEngine.isFullyWithinBounds(rect: desiredRect) {
                    context.beginPage()
                    imageNumberForPage = 0
                    desiredRect = blockLayoutEngine.rect(atIndex: UInt(imageNumberForPage))
                }

                let resized = imageResizer.resize(image: image, to: desiredRect.size)
                resized.draw(in: desiredRect)
            }
        }
        return PDFDocument(data: data)
    }

    private func titleLabel(for label: DataBlockLabel, pageRect: CGRect) -> (NSAttributedString, CGRect) {
        let attributedTitle = NSAttributedString(
            string: label.text,
            attributes: [
                NSAttributedString.Key.font: label.font,
            ]
        )
        let titleSize = attributedTitle.size()
        let titleRect = CGRect(
            x: (pageRect.width - titleSize.width) / 2.0,
            y: label.padding.top,
            width: titleSize.width,
            height: titleSize.height + label.padding.bottom
        )
        return (attributedTitle, titleRect)
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
