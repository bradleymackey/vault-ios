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

    private let store: any BackupPasswordStore
    private var initialPassword: BackupPassword?

    public init(store: any BackupPasswordStore) {
        self.store = store
        initialPassword = try? store.fetchPassword()
    }

    public func stageImport(password: BackupPassword) {
        importState = .staged(password)
        if let initialPassword {
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
            try store.set(password: password)
            importState = .imported
        } catch {
            importState = .error
        }
    }
}
