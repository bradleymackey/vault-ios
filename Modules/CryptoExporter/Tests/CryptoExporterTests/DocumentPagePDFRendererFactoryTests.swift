import CryptoExporter
import Foundation
import XCTest

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

    func test_makeRenderer_formatCreatorIsApplicationName() throws {
        let applicationName = UUID().uuidString
        let sut = makeSUT(applicationName: applicationName)

        let renderer = sut.makeRenderer()

        let format = try XCTUnwrap(renderer.format as? UIGraphicsPDFRendererFormat)
        XCTAssertEqual(format.documentInfo(forKey: kCGPDFContextCreator) as? String?, applicationName)
    }

    func test_makeRenderer_formatAuthorIsAuthorName() throws {
        let authorName = UUID().uuidString
        let sut = makeSUT(authorName: authorName)

        let renderer = sut.makeRenderer()

        let format = try XCTUnwrap(renderer.format as? UIGraphicsPDFRendererFormat)
        XCTAssertEqual(format.documentInfo(forKey: kCGPDFContextAuthor) as? String?, authorName)
    }

    // MARK: - Helpers

    private func makeSUT(size: PDFDocumentSize = .usLetter, applicationName: String? = "Any", authorName: String? = "Any") -> DocumentPagePDFRendererFactory {
        DocumentPagePDFRendererFactory(size: size, applicationName: applicationName, authorName: authorName)
    }
}

private extension UIGraphicsPDFRendererFormat {
    func documentInfo(forKey key: String) -> Any? {
        documentInfo[key]
    }

    func documentInfo(forKey key: CFString) -> Any? {
        documentInfo[key as String]
    }
}
