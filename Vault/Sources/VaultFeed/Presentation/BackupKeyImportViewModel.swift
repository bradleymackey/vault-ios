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

    public private(set) var importState: ImportState = .waiting

    private let store: any BackupPasswordStore

    public init(store: any BackupPasswordStore) {
        self.store = store
    }

    public func stageImport(password: BackupPassword) {
        importState = .staged(password)
    }

    public func commitStagedImport() {
        guard case let .staged(password) = importState else { return }
        do {
            try store.set(password: password)
            importState = .imported
        } catch {
            importState = .error
        }
    }
}
