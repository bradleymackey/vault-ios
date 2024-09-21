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
            "Ready to Import"
        case .merge:
            "Ready to Merge"
        case .override:
            "Ready to Override"
        }
    }

    public var readyToImportDescription: String {
        switch self {
        case .toEmptyVault:
            "Import the backup into your vault to populate it. There's nothing in your vault at the moment."
        case .merge:
            "Importing this backup will merge with the existing data in your vault. If you have the same item in both the backup and your vault, the more recent version of each item will be used."
        case .override:
            "Importing this backup will override the existing data in your vault. All existing data will be lost!"
        }
    }
}
