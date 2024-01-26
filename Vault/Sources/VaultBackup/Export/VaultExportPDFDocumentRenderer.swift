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

    public func render(document: VaultExportPayload) throws -> PDFDocument {
        var documentContent: [DataBlockDocument.Content] = [
            .title(.init(
                text: localized(key: "Vault Export"),
                font: .systemFont(ofSize: 18, weight: .bold),
                padding: .init(top: 0, left: 0, bottom: 8, right: 0)
            )),
        ]

        if !document.userDescription.isEmpty {
            let userDescription: [DataBlockDocument.Content] = document.userDescription.split(separator: "\n")
                .compactMap { text in
                    if text.isEmpty { return nil }
                    return .title(.init(
                        text: String(text),
                        font: .systemFont(ofSize: 12),
                        padding: .init(top: 8, left: 0, bottom: 0, right: 0)
                    ))
                }
            documentContent.append(contentsOf: userDescription)
        }

        documentContent.append(.title(.init(
            text: localized(key: "To import this backup, scan all the QR codes below from all pages."),
            font: .systemFont(ofSize: 10),
            textColor: .gray,
            padding: .init(top: 12, left: 0, bottom: 12, right: 0)
        )))

        func render(totalPageCount: Int?) throws -> PDFDocument {
            let finalPageCount = totalPageCount ?? 0
            let document = DataBlockDocument(
                headerGenerator: VaultExportDataBlockHeaderGenerator(
                    dateCreated: document.created,
                    totalNumberOfPages: finalPageCount
                ),
                content: documentContent
            )
            return try renderer.render(document: document)
        }

        // The first pass render determines how many pages there actually are.
        let firstPassRender = try render(totalPageCount: nil)
        return try render(totalPageCount: firstPassRender.pageCount)
    }
}
