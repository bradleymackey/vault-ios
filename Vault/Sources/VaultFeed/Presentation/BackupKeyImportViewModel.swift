import Foundation
import VaultBackup

@MainActor
@Observable
public final class BackupKeyImportViewModel {
    public enum ImportState {
        case waiting
        case imported
        case error
    }

    public private(set) var importState: ImportState = .waiting

    private let importer: any BackupPasswordImporter

    public init(importer: any BackupPasswordImporter) {
        self.importer = importer
    }

    public func importPassword(data: Data) {
        do {
            try importer.importAndOverridePassword(from: data)
            importState = .imported
        } catch {
            importState = .error
        }
    }
}
