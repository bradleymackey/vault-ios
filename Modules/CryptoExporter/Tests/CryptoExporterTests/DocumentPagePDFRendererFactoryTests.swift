import CryptoExporter
import Foundation
import XCTest

/// Creates a rendering context where PDFs will be drawn onto.
protocol PDFRendererFactory {
    func makeRenderer() -> UIGraphicsPDFRenderer
}

/// Produces renderers optimized for rendering a standard size document.
struct DocumentPagePDFRendererFactory: PDFRendererFactory {
    let size: PDFDocumentSize
    var applicationName: String?
    var authorName: String?

    func makeRenderer() -> UIGraphicsPDFRenderer {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetadata as [String: Any]

        return UIGraphicsPDFRenderer(bounds: pageRect(), format: format)
    }

    private func pageRect() -> CGRect {
        let (pageWidth, pageHeight) = size.pointSize()
        let size = CGSize(width: pageWidth, height: pageHeight)
        return CGRect(origin: .zero, size: size)
    }

    private var pdfMetadata: [CFString: String] {
        var metadata = [CFString: String]()
        return metadata
    }
}

final class DocumentPagePDFRendererFactoryTests: XCTestCase {
    func test_makeRenderer_rendererHasSpecifiedSizeSet() {
        let documentSize = PDFDocumentSize.usLetter
        let sut = makeSUT(size: documentSize)

        let renderer = sut.makeRenderer()

        let expectedSize = documentSize.pointSize()
        let actualSize = renderer.format.bounds.size
        XCTAssertEqual(actualSize.width, expectedSize.width)
        XCTAssertEqual(actualSize.height, expectedSize.height)
    }

    func test_makeRenderer_rendererStartsAtOrigin() {
        let documentSize = PDFDocumentSize.usLetter
        let sut = makeSUT(size: documentSize)

        let renderer = sut.makeRenderer()

        let actualOrigin = renderer.format.bounds.origin
        XCTAssertEqual(actualOrigin, .zero)
    }

    // MARK: - Helpers

    private func makeSUT(size: PDFDocumentSize = .usLetter) -> DocumentPagePDFRendererFactory {
        DocumentPagePDFRendererFactory(size: size)
    }
}
