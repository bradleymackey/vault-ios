import CryptoDocumentExporter
import Foundation
import PDFKit
import TestHelpers
import XCTest
@testable import VaultBackup

final class VaultExportPDFDocumentRendererTests: XCTestCase {
    func test_init_doesNotHaveAnySideEffects() {
        let renderer = PDFDocumentRendererMock()

        _ = makeSUT(documentRenderer: renderer)

        XCTAssertEqual(renderer.renderCallCount, 0)
    }

    func test_render_noPagesGeneratesError() throws {
        let exportPayload = VaultExportPayload(
            encryptedVault: EncryptedVault(
                data: Data(),
                authentication: Data(),
                encryptionIV: Data(),
                keygenSalt: Data(),
                keygenSignature: "my-signature"
            ),
            userDescription: "my vault",
            created: Date(timeIntervalSince1970: 2000)
        )
        let renderer = makeRendererMock(pdfDocument: .noPages)
        let sut = makeSUT(documentRenderer: renderer)

        XCTAssertThrowsError(try sut.render(document: exportPayload))
    }

    func test_render_rendersVaultParsedToDocument() throws {
        let exportPayload = VaultExportPayload(
            encryptedVault: EncryptedVault(
                data: Data(),
                authentication: Data(),
                encryptionIV: Data(),
                keygenSalt: Data(),
                keygenSignature: "my-signature"
            ),
            userDescription: "my vault",
            created: Date(timeIntervalSince1970: 2000)
        )
        let pdfDocument = PDFDocument.onePage
        let renderer = makeRendererMock(pdfDocument: pdfDocument)
        let sut = makeSUT(documentRenderer: renderer)

        let document = try sut.render(document: exportPayload)

        XCTAssertIdentical(
            document,
            pdfDocument,
            "Document should be returned from the block renderer"
        )
        XCTAssertEqual(renderer.renderCallCount, 2, "Renders twice, first pass and final render")
        XCTAssertEqual(renderer.renderArgValues.last?.content.count, 4)
    }
}

// MARK: - Helpers

extension VaultExportPDFDocumentRendererTests {
    private func makeSUT(
        documentRenderer: PDFDocumentRendererMock = makeRendererMock(),
        file _: StaticString = #filePath,
        line _: UInt = #line
    ) -> VaultExportPDFDocumentRenderer<PDFDocumentRendererMock> {
        let sut = VaultExportPDFDocumentRenderer(renderer: documentRenderer, dataShardBuilder: DataShardBuilder())
        return sut
    }
}

private func makeRendererMock(pdfDocument: PDFDocument = PDFDocument()) -> PDFDocumentRendererMock {
    let renderer = PDFDocumentRendererMock()
    renderer.renderHandler = { _ in pdfDocument }
    return renderer
}

extension PDFDocument {
    fileprivate static var noPages: PDFDocument {
        PDFDocument()
    }

    fileprivate static var onePage: PDFDocument {
        let renderer = UIGraphicsPDFRenderer()
        let data = renderer.pdfData { context in
            context.beginPage()
        }
        return PDFDocument(data: data)!
    }
}
