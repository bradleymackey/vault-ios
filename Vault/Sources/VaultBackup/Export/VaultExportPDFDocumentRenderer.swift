import CryptoDocumentExporter
import Foundation
import PDFKit

/// A renderer for an exported vault.
///
/// Internally uses a data block renderer to render the data to a PDF.
public struct VaultExportPDFDocumentRenderer<Renderer>: PDFDocumentRenderer
    where
    Renderer: PDFDocumentRenderer,
    Renderer.Document == DataBlockDocument
{
    public typealias Document = VaultExportPayload

    private let renderer: Renderer

    public init(renderer: Renderer) {
        self.renderer = renderer
    }

    public func render(document _: VaultExportPayload) throws -> PDFDocument {
        func render(totalPageCount: Int?) throws -> PDFDocument {
            let finalPageCount = totalPageCount ?? 0
            let document = DataBlockDocument(
                headerGenerator: VaultExportDataBlockHeaderGenerator(
                    dateCreated: Date(),
                    totalNumberOfPages: finalPageCount
                ),
                content: [
                    .title(.init(text: localized(key: "Vault Export"), font: .systemFont(ofSize: 14), padding: .zero)),
                ]
            )
            return try renderer.render(document: document)
        }

        // The first pass render determines how many pages there actually are.
        let firstPassRender = try render(totalPageCount: nil)
        return try render(totalPageCount: firstPassRender.pageCount)
    }
}
