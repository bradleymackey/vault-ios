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
    private let authenticationService: DeviceAuthenticationService

    public init(exporter: BackupPasswordExporter, authenticationService: DeviceAuthenticationService) {
        self.exporter = exporter
        self.authenticationService = authenticationService
    }

    public func createExport() async {
        do {
            try await authenticationService.validateAuthentication(reason: "Authentication to export your backup key.")
            let exportData = try await exporter.makeExport()
            exportState = .exported(exportData)
        } catch {
            exportState = .error(error)
        }
    }
}
