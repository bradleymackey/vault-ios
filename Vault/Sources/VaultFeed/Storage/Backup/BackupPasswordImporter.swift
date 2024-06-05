import Foundation

public final class BackupPasswordImporter {
    private let store: any BackupPasswordStore

    public init(store: any BackupPasswordStore) {
        self.store = store
    }

    public enum ImportError: Error {
        case incompatibleVersion
    }

    public func importAndOverridePassword(from export: BackupPasswordExport) throws {
        guard export.version.isCompatible(with: "1.0.0") else {
            throw ImportError.incompatibleVersion
        }
        let newPassword = BackupPassword(key: export.key, salt: export.salt)
        try store.set(password: newPassword)
    }
}
