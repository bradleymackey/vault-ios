import CryptoExporter
import Foundation
import PDFKit
import SnapshotTesting
import XCTest

struct DataBlockExportDocument {
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
    let blockLayout: (CGSize) -> BlockLayout

    init(
        rendererFactory: RendererFactory,
        imageRenderer: ImageRenderer,
        blockLayout: @escaping (CGSize) -> BlockLayout
    ) {
        self.rendererFactory = rendererFactory
        self.imageRenderer = imageRenderer
        self.blockLayout = blockLayout
    }

    func render(document: DataBlockExportDocument) -> PDFDocument? {
        let renderer = rendererFactory.makeRenderer()
        let data = renderer.pdfData { context in
            context.beginPage()

            let imageResizer = UIImageResizer(mode: .noSmoothing)
            let blockLayoutEngine = blockLayout(context.pdfContextBounds.size)

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
}

final class PDFDataBlockRendererTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    func test_render_drawsEmptyPDFDocument() throws {
        let renderer = StubPDFRendererFactory()
        let sut = makeSUT(renderer: renderer)
        let pdf = try XCTUnwrap(sut.render(document: emptyDocument()))

        assertSnapshot(matching: pdf, as: .pdf())
    }

    func test_render_drawsSingleImage() throws {
        let renderer = StubPDFRendererFactory()
        let sut = makeSUT(renderer: renderer)
        let document = DataBlockExportDocument(dataBlockImageData: [anyData()])
        let pdf = try XCTUnwrap(sut.render(document: document))

        assertSnapshot(matching: pdf, as: .pdf())
    }

    func test_render_drawsRowOfImages() throws {
        let renderer = StubPDFRendererFactory()
        let sut = makeSUT(renderer: renderer)
        let document = DataBlockExportDocument(dataBlockImageData: [anyData(), anyData(), anyData(), anyData()])
        let pdf = try XCTUnwrap(sut.render(document: document))

        assertSnapshot(matching: pdf, as: .pdf())
    }

    func test_render_drawsMultiplePagesOfImages() throws {
        let renderer = StubPDFRendererFactory()
        let sut = makeSUT(renderer: renderer)
        let document = DataBlockExportDocument(dataBlockImageData: Array(repeating: anyData(), count: 14))
        let pdf = try XCTUnwrap(sut.render(document: document))

        assertSnapshot(matching: pdf, as: .pdf(page: 1), named: "page1")
        assertSnapshot(matching: pdf, as: .pdf(page: 2), named: "page2")
    }

    // MARK: - Helpers

    private func makeSUT(
        renderer: StubPDFRendererFactory = StubPDFRendererFactory(),
        imageRenderer: RGBCyclingStubColorImageRenderer = RGBCyclingStubColorImageRenderer()
    ) -> some PDFDocumentRenderer<DataBlockExportDocument> {
        PDFDataBlockRenderer(
            rendererFactory: renderer,
            imageRenderer: imageRenderer,
            blockLayout: { size in
                VerticalTilingDataBlockLayout(bounds: size, tilesPerRow: 3, margin: 10, spacing: 5)
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
