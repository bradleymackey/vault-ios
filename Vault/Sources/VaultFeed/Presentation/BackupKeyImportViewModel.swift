import Foundation
import VaultBackup

@MainActor
@Observable
public final class BackupKeyImportViewModel {
    public enum ImportState: Equatable {
        case waiting
        /// Data is ready to import
        case staged(BackupPassword)
        case imported
        case error
    }

    public enum ImportOverrideBehaviour: Equatable {
        case overridesExisting
        case matchesExisting
    }

    public private(set) var importState: ImportState = .waiting
    public private(set) var overrideBehaviour: ImportOverrideBehaviour?

    private let dataModel: VaultDataModel

    public init(dataModel: VaultDataModel) {
        self.dataModel = dataModel
    }

    public func stageImport(password: BackupPassword) async {
        importState = .staged(password)
        await dataModel.loadBackupPassword()
        if case let .fetched(initialPassword) = dataModel.backupPassword {
            if password == initialPassword {
                overrideBehaviour = .matchesExisting
            } else {
                overrideBehaviour = .overridesExisting
            }
        } else {
            overrideBehaviour = nil
        }
    }

    public func commitStagedImport() {
        guard case let .staged(password) = importState else { return }
        do {
            try dataModel.store(backupPassword: password)
            importState = .imported
        } catch {
            importState = .error
        }
    }
}
