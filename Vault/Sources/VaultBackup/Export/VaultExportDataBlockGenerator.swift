import CryptoDocumentExporter
import Foundation

/// Helper for creating the data block document from an exported vault.
struct VaultExportDataBlockGenerator {
    private let payload: VaultExportPayload

    init(payload: VaultExportPayload) {
        self.payload = payload
    }

    func makeDocument(knownPageCount: Int) throws -> DataBlockDocument {
        var document = DataBlockDocument(
            headerGenerator: VaultExportDataBlockHeaderGenerator(
                dateCreated: payload.created,
                totalNumberOfPages: knownPageCount
            ),
            content: []
        )
        document.content.append(.title(makeTitle()))
        document.content.append(contentsOf: makeUserDescriptionLabels().map { .title($0) })
        document.content.append(.title(makeQRCodeHelperLabel()))
        return document
    }
}

extension VaultExportDataBlockGenerator {
    private func makeTitle() -> DataBlockLabel {
        .init(
            text: localized(key: "Vault Export"),
            font: .systemFont(ofSize: 18, weight: .bold),
            padding: .init(top: 0, left: 0, bottom: 8, right: 0)
        )
    }

    private func makeUserDescriptionLabels() -> [DataBlockLabel] {
        payload.userDescription
            .split(separator: "\n")
            .compactMap { text in
                if text.isEmpty { return nil }
                return .init(
                    text: String(text),
                    font: .systemFont(ofSize: 12),
                    padding: .init(top: 8, left: 0, bottom: 0, right: 0)
                )
            }
    }

    private func makeQRCodeHelperLabel() -> DataBlockLabel {
        .init(
            text: localized(key: "To import this backup, scan all the QR codes below from all pages."),
            font: .systemFont(ofSize: 10),
            textColor: .gray,
            padding: .init(top: 12, left: 0, bottom: 12, right: 0)
        )
    }
}
