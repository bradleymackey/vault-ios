import CryptoDocumentExporter
import Foundation
import TestHelpers
import VaultBackup
import XCTest

final class VaultDocumentExporterTests: XCTestCase {
    func test_init_doesNotHaveAnySideEffects() {
        let renderer = PDFDocumentRendererSpy<Void>()

        _ = makeSUT(documentRenderer: renderer)

        XCTAssertFalse(renderer.renderDocumentCalled)
    }
}

// MARK: - Helpers

extension VaultDocumentExporterTests {
    private func makeSUT(
        documentRenderer: PDFDocumentRendererSpy<Void> = PDFDocumentRendererSpy(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> VaultDocumentExporter {
        let sut = VaultDocumentExporter(documentRenderer: documentRenderer)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}
