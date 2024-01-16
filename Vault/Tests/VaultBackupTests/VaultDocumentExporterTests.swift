import CryptoDocumentExporter
import Foundation
import PDFKit
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
        let renderer = MockPDFDocumentRenderer()

        _ = makeSUT(documentRenderer: renderer)

        XCTAssertEqual(renderer.calledMethods, [])
    }
}

// MARK: - Helpers

extension VaultDocumentExporterTests {
    private func makeSUT(
        documentRenderer: MockPDFDocumentRenderer = MockPDFDocumentRenderer(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> VaultDocumentExporter {
        let sut = VaultDocumentExporter(documentRenderer: documentRenderer)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}

class MockPDFDocumentRenderer: PDFDocumentRenderer {
    typealias Document = Void

    private(set) var calledMethods = [StubbedMethod]()

    enum StubbedMethod: Equatable {
        case render
    }

    var renderValue: PDFDocument? = nil
    func render(document _: Document) -> PDFDocument? {
        calledMethods.append(.render)
        return renderValue
    }
}
