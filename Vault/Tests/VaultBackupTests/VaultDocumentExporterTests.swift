import CryptoDocumentExporter
import Foundation
import TestHelpers
import VaultBackup
import XCTest

/// Exports an encrypted vault to a document format, for external saving or printing.
///
/// This is a very manual form of backup, but is useful for cold or long-term storage.
final class VaultDocumentExporter {
    private let documentRenderer: any PDFDocumentRenderer
    init(documentRenderer: any PDFDocumentRenderer) {
        self.documentRenderer = documentRenderer
    }
}

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
