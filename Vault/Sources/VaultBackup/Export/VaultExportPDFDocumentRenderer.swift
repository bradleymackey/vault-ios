import CryptoDocumentExporter
import Foundation
import PDFKit
import VaultCore

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

    enum RenderError: Error {
        case noPagesGenerated
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
        let finalRender = try render(totalPageCount: firstPassRender.pageCount)

        guard let firstPage = finalRender.page(at: 0) else {
            throw RenderError.noPagesGenerated
        }

        let vaultAnnotation = try makeVaultAnnotation(vault: document.encryptedVault)
        firstPage.addAnnotation(vaultAnnotation)

        return finalRender
    }

    private func makeVaultAnnotation(vault: EncryptedVault) throws -> PDFAnnotation {
        let annotation = PDFAnnotation(
            bounds: CGRect(x: -100, y: -100, width: 100, height: 100),
            forType: .circle,
            withProperties: nil
        )
        let encoded = try makeEncodedVault(vault: vault)
        annotation.contents = "\(VaultIdentifiers.Backup.encryptedVaultData):" + encoded
        annotation.color = UIColor.clear
        annotation.fontColor = UIColor.clear
        annotation.backgroundColor = UIColor.clear
        return annotation
    }

    private func makeEncodedVault(vault: EncryptedVault) throws -> String {
        let coder = EncryptedVaultCoder()
        let encodedVault = try coder.encode(vault: vault)
        return encodedVault.base64EncodedString()
    }
}
