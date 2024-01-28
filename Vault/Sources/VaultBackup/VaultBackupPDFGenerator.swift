import CryptoDocumentExporter
import Foundation
import PDFKit

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
        return try documentRenderer.render(document: payload)
    }

    private var dataShardBuilder: DataShardBuilder {
        #if DEBUG
        // Use a deterministic group ID in debug builds for deterministic test results.
        return DataShardBuilder(groupIDGenerator: { UUID(uuidString: "00000000-0000-0000-0000-000000000000")! })
        #else
        return DataShardBuilder()
        #endif
    }
}
