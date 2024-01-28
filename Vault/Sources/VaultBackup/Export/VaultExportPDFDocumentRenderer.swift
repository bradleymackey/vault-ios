import CryptoDocumentExporter
import Foundation
import PDFKit

/// A renderer for an exported vault.
///
/// Internally uses a data block renderer to render the data to a PDF.
struct VaultExportPDFDocumentRenderer<Renderer>: PDFDocumentRenderer
    where
    Renderer: PDFDocumentRenderer,
    Renderer.Document == DataBlockDocument
{
    typealias Document = VaultExportPayload

    private let renderer: Renderer
    private let dataShardBuilder: DataShardBuilder

    init(renderer: Renderer, dataShardBuilder: DataShardBuilder) {
        self.renderer = renderer
        self.dataShardBuilder = dataShardBuilder
    }

    func render(document: VaultExportPayload) throws -> PDFDocument {
        let generator = VaultExportDataBlockGenerator(payload: document, dataShardBuilder: dataShardBuilder)

        func render(totalPageCount: Int?) throws -> PDFDocument {
            let finalPageCount = totalPageCount ?? 0
            let document = try generator.makeDocument(knownPageCount: finalPageCount)
            return try renderer.render(document: document)
        }

        // The first pass render determines how many pages there actually are.
        let firstPassRender = try render(totalPageCount: nil)
        return try render(totalPageCount: firstPassRender.pageCount)
    }
}
