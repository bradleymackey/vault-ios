import Foundation
import VaultBackup

@MainActor
@Observable
public final class BackupKeyExportViewModel {
    public enum ExportState {
        case waiting
        case exported(Data)
        case error(any Error)
    }

    public var exportState: ExportState = .waiting

    private let exporter: BackupPasswordExporter

    public init(exporter: BackupPasswordExporter) {
        self.exporter = exporter
    }

    public func createExport() {
        do {
            let exportData = try exporter.makeExport()
            exportState = .exported(exportData)
        } catch {
            exportState = .error(error)
        }
    }
}
