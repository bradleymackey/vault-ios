import Foundation

/// View model for the backup creation view.
@MainActor
@Observable
public final class BackupCreateViewModel {
    public let strings = Strings()
    public init() {}
}

// MARK: - Strings

extension BackupCreateViewModel {
    @MainActor
    public struct Strings {
        init() {}

        public let homeTitle = localized(key: "backupCreate.title")
        public let backupPasswordSectionTitle = localized(key: "backupPasswordState.section.title")
        public let backupPasswordCreateTitle = localized(key: "backupPasswordState.create.title")
        public let backupPasswordUpdateTitle = localized(key: "backupPasswordState.update.title")
        public let backupPasswordExportTitle = localized(key: "backupPasswordState.export.title")
        public let backupPasswordLoadingTitle = localized(key: "backupPasswordState.loading.title")
        public let backupPasswordErrorTitle = localized(key: "backupPasswordState.retrieveError.title")
        public let backupPasswordErrorDetail = localized(key: "backupPasswordState.retrieveError.detail")
    }
}
