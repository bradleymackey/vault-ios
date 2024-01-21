import CryptoDocumentExporter
import Foundation

/// Helper for creating the data block document from an exported vault.
struct VaultExportDataBlockGenerator {
    private let payload: VaultExportPayload

    init(payload: VaultExportPayload) {
        self.payload = payload
    }

    func makeDocument() throws -> DataBlockDocument {
        DataBlockDocument(headerForPage: { _ in nil }, titles: [], dataBlockImageData: [])
    }
}
