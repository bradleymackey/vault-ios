import CryptoDocumentExporter
import Foundation
import PDFKit
import TestHelpers
import VaultBackup
import XCTest

final class VaultExportPDFDocumentRendererTests: XCTestCase {
    func test_init_doesNotHaveAnySideEffects() {
        let renderer = RendererSpy()

        _ = makeSUT(documentRenderer: renderer)

        XCTAssertFalse(renderer.renderDocumentCalled)
    }

    func test_render_rendersVaultParsedToDocument() throws {
        let exportPayload = VaultExportPayload(
            encryptedVault: EncryptedVault(data: Data(), authentication: Data()),
            userDescription: "my vault",
            created: Date(timeIntervalSince1970: 2000)
        )
        let renderer = makeRendererSpy()
        let sut = makeSUT(documentRenderer: renderer)

        let document = try sut.render(document: exportPayload)

        XCTAssertIdentical(
            document,
            renderer.renderDocumentReturnValue,
            "Document should be returned from the block renderer"
        )
        XCTAssertEqual(renderer.renderDocumentCallsCount, 2, "Renders twice, first pass and final render")
        XCTAssertEqual(renderer.renderDocumentReceivedDocument?.content.count, 3)
    }
}

// MARK: - Helpers

extension VaultExportPDFDocumentRendererTests {
    private func makeSUT(
        documentRenderer: RendererSpy = makeRendererSpy(),
        file _: StaticString = #filePath,
        line _: UInt = #line
    ) -> VaultExportPDFDocumentRenderer<RendererSpy> {
        let sut = VaultExportPDFDocumentRenderer(renderer: documentRenderer)
        return sut
    }
}

private typealias RendererSpy = PDFDocumentRendererSpy<DataBlockDocument>

private func makeRendererSpy() -> RendererSpy {
    let renderer = RendererSpy()
    renderer.renderDocumentReturnValue = PDFDocument()
    return renderer
}
