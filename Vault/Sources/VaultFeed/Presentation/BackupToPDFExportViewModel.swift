import Foundation

@MainActor
@Observable
public final class BackupToPDFExportViewModel {
    public enum ExportState: Equatable {
        case waiting
        case exported
        case error
    }

    public private(set) var exportState: ExportState = .waiting

    public func exportToPDF() {
        // TODO: - implement this
    }
}
