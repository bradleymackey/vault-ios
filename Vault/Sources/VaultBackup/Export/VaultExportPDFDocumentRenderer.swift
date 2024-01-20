import CryptoDocumentExporter
import Foundation
import PDFKit

public struct VaultExportPDFDocumentRenderer: PDFDocumentRenderer {
    public typealias Document = VaultExportPayload

    public func render(document _: VaultExportPayload) throws -> PDFDocument {
        PDFDocument()
    }
}
