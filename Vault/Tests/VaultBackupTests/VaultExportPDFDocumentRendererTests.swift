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

    func test_render_rendersVaultParsedToDocument() throws {
        let exportPayload = VaultExportPayload(
            encryptedVault: EncryptedVault(data: Data(), authentication: Data()),
            userDescription: "my vault",
            created: Date(timeIntervalSince1970: 2000)
        )
        let pdfDocument = PDFDocument()
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
