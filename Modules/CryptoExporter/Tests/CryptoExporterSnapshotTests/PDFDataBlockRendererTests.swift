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
        let pdfImage = try XCTUnwrap(pdf.asImage())

        assertSnapshot(matching: pdfImage, as: .image)
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

extension UIImage {
    static func from(color: UIColor) -> UIImage {
        let size = CGSize(width: 10, height: 10)
        return UIGraphicsImageRenderer(size: size).image { context in
            context.cgContext.setFillColor(color.cgColor)
            context.fill(CGRect(origin: .zero, size: size))
        }
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

extension PDFDocument {
    func asImage(page: Int = 1) -> UIImage? {
        guard let data = dataRepresentation() else { return nil }
        let cfData = data as CFData
        guard let provider = CGDataProvider(data: cfData) else { return nil }
        guard let pdfDoc = CGPDFDocument(provider) else { return nil }
        guard let page = pdfDoc.page(at: page) else { return nil }

        let pageRect = page.getBoxRect(.mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        return renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(pageRect)

            ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)

            ctx.cgContext.drawPDFPage(page)
        }
    }
}

extension Snapshotting where Value == Data, Format == Data {
    static var pdf: Snapshotting {
        .init(
            pathExtension: "pdf",
            diffing: .init(toData: { $0 }, fromData: { $0 }) { old, new in
                guard old != new else { return nil }
                let message = old.count == new.count
                    ? "Expected data in pdf to match"
                    : "Expected \(new) to match \(old)"
                return (message, [])
            }
        )
    }
}
