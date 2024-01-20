import CryptoDocumentExporter
import Foundation
import PDFKit

/// Exports an encrypted vault to a document format, for external saving or printing.
///
/// This is a very manual form of backup, but is useful for cold or long-term storage.
public final class VaultDocumentExporter {
    private let documentRenderer: any PDFDocumentRenderer
    public init(documentRenderer: any PDFDocumentRenderer) {
        self.documentRenderer = documentRenderer
    }

    public func createDocument(exportPayload _: VaultExportPayload) -> PDFDocument {
        PDFDocument()
    }
}
