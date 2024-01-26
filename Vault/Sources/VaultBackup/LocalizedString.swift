import Foundation

/// Helper for getting a localized string from the current module.
func localized(key: String.LocalizationValue) -> String {
    String(localized: key, table: "VaultBackup")
}
