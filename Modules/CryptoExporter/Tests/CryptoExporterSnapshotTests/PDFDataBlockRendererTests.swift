import CryptoExporter
import Foundation
import PDFKit
import SnapshotTesting
import XCTest

protocol PDFDocumentRenderer<Document> {
    associatedtype Document
    func render(document: Document) -> PDFDocument?
}

protocol PDFImageRenderer {
    func makeImage(fromData data: Data) -> UIImage?
}

class PDFDataBlockRenderer<
    RendererFactory: PDFRendererFactory,
    ImageRenderer: PDFImageRenderer
>: PDFDocumentRenderer {
    typealias Document = Void

    let rendererFactory: RendererFactory
    let imageRenderer: ImageRenderer

    init(
        rendererFactory: RendererFactory,
        imageRenderer: ImageRenderer
    ) {
        self.rendererFactory = rendererFactory
        self.imageRenderer = imageRenderer
    }

    func render(document _: Void) -> PDFDocument? {
        let renderer = rendererFactory.makeRenderer()
        let data = renderer.pdfData { context in
            context.beginPage()
        }
        return PDFDocument(data: data)
    }
}

final class PDFDataBlockRendererTests: XCTestCase {
    func test_render_drawsEmptyPDFDocument() throws {
        let renderer = StubPDFRendererFactory()
        let sut = makeSUT(renderer: renderer)
        let pdf = try XCTUnwrap(sut.render(document: ()))

        assertSnapshot(matching: pdf, as: .pdf())
    }

    // MARK: - Helpers

    private func makeSUT(
        renderer: StubPDFRendererFactory = StubPDFRendererFactory(),
        imageRenderer: StubColorImageRenderer = StubColorImageRenderer(color: .red)
    ) -> some PDFDocumentRenderer<Void> {
        PDFDataBlockRenderer(
            rendererFactory: renderer,
            imageRenderer: imageRenderer
        )
    }

    private func anyData() -> Data {
        Data(repeating: 0xFF, count: 10)
    }
}

private struct StubPDFRendererFactory: PDFRendererFactory {
    var size = CGSize(width: 200, height: 200)
    var rect: CGRect {
        CGRect(origin: .zero, size: size)
    }

    func makeRenderer() -> UIGraphicsPDFRenderer {
        UIGraphicsPDFRenderer(bounds: rect)
    }
}

private struct StubColorImageRenderer: PDFImageRenderer {
    var color: UIColor
    func makeImage(fromData _: Data) -> UIImage? {
        UIImage.from(color: color)
    }
}
