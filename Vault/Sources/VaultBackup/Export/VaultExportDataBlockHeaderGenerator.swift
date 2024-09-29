import Foundation
import VaultExport

struct VaultExportDataBlockHeaderGenerator: DataBlockHeaderGenerator {
    let dateCreated: Date
    let totalNumberOfPages: Int

    func makeHeader(pageNumber: Int) -> DataBlockHeader? {
        let date = dateFormatter.string(from: dateCreated)
        let dateText = localized(key: "Created \(date)")
        let pageNumber = localized(key: "Page \(pageNumber) of \(totalNumberOfPages)")
        return DataBlockHeader(left: dateText, right: pageNumber)
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}
