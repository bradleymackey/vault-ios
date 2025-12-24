import Foundation

/// View model for the backup restoration view.
@MainActor
@Observable
public final class BackupRestoreViewModel {
    public let strings = Strings()
    public init() {}
}

// MARK: - Strings

extension BackupRestoreViewModel {
    @MainActor
    public struct Strings {
        init() {}

        public let homeTitle = localized(key: "backupRestore.title")
        public let backupPasswordImportTitle = localized(key: "backupPasswordState.import.title")
    }
}
