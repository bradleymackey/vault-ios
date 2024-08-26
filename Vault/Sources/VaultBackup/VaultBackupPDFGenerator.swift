import CryptoDocumentExporter
import Foundation
import ImageTools
import PDFKit
import VaultCore

public struct VaultBackupPDFGenerator {
    public var size: any PDFDocumentSize
    public var documentTitle: String
    public var applicationName: String
    public var authorName: String

    public init(size: any PDFDocumentSize, documentTitle: String, applicationName: String, authorName: String) {
        self.size = size
        self.documentTitle = documentTitle
        self.applicationName = applicationName
        self.authorName = authorName
    }

    public func makePDF(payload: VaultExportPayload) throws -> PDFDocument {
        let blockDocumentRenderer = PDFDataBlockDocumentRenderer(
            documentSize: size,
            rendererFactory: PDFDocumentPageRendererFactory(
                size: size,
                applicationName: applicationName,
                authorName: authorName,
                documentTitle: documentTitle
            ),
            imageRenderer: QRCodeImageRenderer(),
            blockLayout: { rect in
                VerticalTilingDataBlockLayout(
                    bounds: rect,
                    tilesPerRow: size.idealNumberOfHorizontalSquaresForPaperSize,
                    spacing: 5
                )
            }
        )
        let documentRenderer = VaultExportPDFDocumentRenderer(
            renderer: blockDocumentRenderer,
            dataShardBuilder: dataShardBuilder
        )
        let renderedDocument = try documentRenderer.render(document: payload)
        if renderedDocument.documentAttributes == nil {
            renderedDocument.documentAttributes = [:]
        }
        renderedDocument
            .documentAttributes?[VaultIdentifiers.Backup.encryptedVaultData] =
            try makeEncodedVault(vault: payload.encryptedVault)
        return renderedDocument
    }

    private var dataShardBuilder: DataShardBuilder {
        #if DEBUG
        // Use a deterministic group ID in debug builds for deterministic test results.
        return DataShardBuilder(groupIDGenerator: { 0 })
        #else
        return DataShardBuilder()
        #endif
    }

    private func makeEncodedVault(vault: EncryptedVault) throws -> String {
        let coder = EncryptedVaultCoder()
        let encodedVault = try coder.encode(vault: vault)
        return encodedVault.base64EncodedString()
    }
}
