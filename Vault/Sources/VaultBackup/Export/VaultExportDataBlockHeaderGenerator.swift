import CryptoDocumentExporter
import Foundation

struct VaultExportDataBlockHeaderGenerator: DataBlockHeaderGenerator {
    let dateCreated: Date
    func makeHeader(pageNumber: Int) -> DataBlockHeader? {
        let dateText = dateFormatter.string(from: dateCreated)
        let pageNumber = "Page \(pageNumber)"
        return DataBlockHeader(left: dateText, right: pageNumber)
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}
