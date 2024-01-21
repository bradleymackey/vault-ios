import CryptoDocumentExporter
import Foundation
import PDFKit

/// A renderer for an exported vault.
///
/// Internally uses a data block renderer to render the data to a PDF.
public struct VaultExportPDFDocumentRenderer<Renderer>: PDFDocumentRenderer
    where
    Renderer: PDFDocumentRenderer,
    Renderer.Document == DataBlockExportDocument
{
    public typealias Document = VaultExportPayload

    private let renderer: Renderer

    public init(renderer: Renderer) {
        self.renderer = renderer
    }

    public func render(document _: VaultExportPayload) throws -> PDFDocument {
        let document = DataBlockExportDocument(
            headerForPage: { _ in nil },
            titles: [.init(text: "My Export", font: .systemFont(ofSize: 14), padding: .zero)],
            dataBlockImageData: []
        )
        return try renderer.render(document: document)
    }
}
