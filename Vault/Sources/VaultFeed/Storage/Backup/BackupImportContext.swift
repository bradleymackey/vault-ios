import Foundation

public enum BackupImportContext: Equatable {
    case toEmptyVault
    case merge
    case override
}

extension BackupImportContext {
    public var readyToImportTitle: String {
        switch self {
        case .toEmptyVault:
            return "Ready to Import"
        case .merge:
            return "Ready to Merge"
        case .override:
            return "Ready to Override"
        }
    }

    public var readyToImportDescription: String {
        switch self {
        case .toEmptyVault:
            return "Import the backup into your vault to populate it. There's nothing in your vault at the moment."
        case .merge:
            return "Importing this backup will merge with the existing data in your vault. If you have the same item in both the backup and your vault, the more recent version of each item will be used."
        case .override:
            return "Importing this backup will override the existing data in your vault. All existing data will be lost!"
        }
    }
}
